#!/usr/bin/env python3
"""Provision GIHC's Migadu mailbox and DNS records idempotently."""

from __future__ import annotations

import argparse
import base64
import json
import subprocess
import sys
import urllib.error
import urllib.request
from typing import Any

DOMAIN = "gihc.online"
MIGADU_API = "https://api.migadu.com/v1"
SIMPLY_API = f"https://api.simply.com/2/my/products/{DOMAIN}/dns/records/"


def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    raise SystemExit(1)


def pass_value(entry: str) -> str:
    try:
        return subprocess.check_output(
            ["pass", entry], text=True, stderr=subprocess.DEVNULL
        ).strip()
    except (FileNotFoundError, subprocess.CalledProcessError):
        fail(f"'{entry}' findes ikke i pass. Se MAIL.md.")


def request_json(
    url: str,
    username: str,
    password: str,
    *,
    method: str = "GET",
    payload: dict[str, Any] | None = None,
    allow_404: bool = False,
) -> Any:
    data = json.dumps(payload).encode() if payload is not None else None
    token = base64.b64encode(f"{username}:{password}".encode()).decode()
    request = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={
            "Authorization": f"Basic {token}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "User-Agent": "GIHC-mail-setup/1.0",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read()
            return json.loads(body) if body else None
    except urllib.error.HTTPError as error:
        if allow_404 and error.code == 404:
            return None
        body = error.read().decode(errors="replace")
        fail(f"{method} {url} svarede HTTP {error.code}: {body[:500]}")
    except urllib.error.URLError as error:
        fail(f"Kunne ikke kontakte {url}: {error.reason}")


def migadu_get(path: str, user: str, token: str, allow_404: bool = False) -> Any:
    return request_json(
        f"{MIGADU_API}{path}", user, token, allow_404=allow_404
    )


def migadu_post(path: str, user: str, token: str, payload: dict[str, Any]) -> Any:
    return request_json(
        f"{MIGADU_API}{path}", user, token, method="POST", payload=payload
    )


def simply_get(user: str, token: str) -> list[dict[str, Any]]:
    result = request_json(SIMPLY_API, user, token)
    return result.get("records", [])


def simply_post(user: str, token: str, payload: dict[str, Any]) -> None:
    request_json(SIMPLY_API, user, token, method="POST", payload=payload)


def normalized_value(value: Any) -> str:
    return str(value).strip().rstrip(".")


def record_name(record: dict[str, Any]) -> str:
    return str(record.get("name", "@")).strip()


def record_type(record: dict[str, Any]) -> str:
    return str(record.get("type", "")).upper()


def record_priority(record: dict[str, Any]) -> int | None:
    value = record.get("priority")
    return int(value) if value is not None else None


def ensure_domain(migadu_user: str, migadu_token: str) -> dict[str, Any]:
    domain = migadu_get(f"/domains/{DOMAIN}", migadu_user, migadu_token, allow_404=True)
    if domain:
        print(f"==> Migadu-domænet {DOMAIN} findes allerede")
        return domain

    print(f"==> Opretter {DOMAIN} hos Migadu")
    return migadu_post(
        "/domains",
        migadu_user,
        migadu_token,
        {
            "name": DOMAIN,
            "create_default_addresses": "true",
            "hosted_dns": "false",
        },
    )


def ensure_mailbox(
    migadu_user: str, migadu_token: str, local_part: str, recovery_email: str
) -> None:
    existing = migadu_get(
        f"/domains/{DOMAIN}/mailboxes/{local_part}",
        migadu_user,
        migadu_token,
        allow_404=True,
    )
    if existing:
        print(f"==> Postkassen {local_part}@{DOMAIN} findes allerede")
        return

    print(f"==> Opretter {local_part}@{DOMAIN} og sender invitation")
    migadu_post(
        f"/domains/{DOMAIN}/mailboxes",
        migadu_user,
        migadu_token,
        {
            "name": "GIHC Mail",
            "local_part": local_part,
            "password_method": "invitation",
            "password_recovery_email": recovery_email,
        },
    )


def migadu_dns_records(migadu_user: str, migadu_token: str) -> list[dict[str, Any]]:
    data = migadu_get(f"/domains/{DOMAIN}/records", migadu_user, migadu_token)
    records: list[dict[str, Any]] = []

    for value in data.get("mx_records", []):
        records.append(
            {
                "type": "MX",
                "name": value["name"],
                "data": value["value"],
                "priority": value.get("priority"),
            }
        )
    for key in ("spf", "dns_verification"):
        value = data.get(key)
        if value:
            records.append(
                {
                    "type": value["type"].upper(),
                    "name": value["name"],
                    "data": value["value"],
                    "priority": value.get("priority"),
                }
            )
    for value in data.get("dkim", []):
        records.append(
            {
                "type": value["type"].upper(),
                "name": value["name"],
                "data": value["value"],
                "priority": value.get("priority"),
            }
        )
    return records


def preflight_dns(
    required: list[dict[str, Any]], existing: list[dict[str, Any]]
) -> None:
    mx_names = {record_name(record) for record in required if record_type(record) == "MX"}
    allowed_mx = {
        (record_name(record), normalized_value(record["data"]).lower())
        for record in required
        if record_type(record) == "MX"
    }
    existing_mx = {
        (record_name(record), normalized_value(record["data"]).lower())
        for record in existing
        if record_type(record) == "MX" and record_name(record) in mx_names
    }
    if existing_mx - allowed_mx:
        fail(
            "Der findes en anden MX-record på samme navn. "
            "Flyt ikke mail uden bevidst at fjerne den gamle leverandør."
        )

    expected_spf = {
        normalized_value(record["data"]).lower()
        for record in required
        if record_type(record) == "TXT"
        and normalized_value(record["data"]).lower().startswith("v=spf1")
    }
    existing_spf = {
        normalized_value(record["data"]).lower()
        for record in existing
        if record_type(record) == "TXT"
        and record_name(record) == "@"
        and normalized_value(record["data"]).lower().startswith("v=spf1")
    }
    if existing_spf - expected_spf:
        fail(
            "Der findes allerede en anden SPF-record på apex. "
            "Flet den bevidst i stedet for at oprette to SPF-records."
        )

    for required_record in required:
        if record_type(required_record) != "CNAME":
            continue
        for existing_record in existing:
            if record_name(existing_record) != record_name(required_record):
                continue
            if (
                record_type(existing_record) != "CNAME"
                or normalized_value(existing_record["data"]).lower()
                != normalized_value(required_record["data"]).lower()
            ):
                fail(
                    f"Navnet {record_name(required_record)} er allerede i brug "
                    "af en anden DNS-record."
                )


def has_record(required: dict[str, Any], existing: list[dict[str, Any]]) -> bool:
    for record in existing:
        if (
            record_type(record) == record_type(required)
            and record_name(record) == record_name(required)
            and normalized_value(record["data"]).lower()
            == normalized_value(required["data"]).lower()
        ):
            if record_type(record) == "MX":
                return record_priority(record) == required.get("priority")
            return True
    return False


def apply_dns(
    required: list[dict[str, Any]], simply_user: str, simply_token: str
) -> None:
    existing = simply_get(simply_user, simply_token)
    preflight_dns(required, existing)

    for record in required:
        if has_record(record, existing):
            print(
                f"==> {record_type(record):5} {record_name(record):18} findes allerede"
            )
            continue
        payload = {
            "type": record_type(record),
            "name": record_name(record),
            "data": normalized_value(record["data"]),
            "ttl": 3600,
            "comment": "GIHC Migadu",
        }
        if record.get("priority") is not None:
            payload["priority"] = int(record["priority"])
        print(
            f"==> Opretter {record_type(record):5} "
            f"{record_name(record):18} {payload['data']}"
        )
        simply_post(simply_user, simply_token, payload)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Opsæt Migadu-mail til GIHC via API."
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Opret domæne, postkasse og DNS-records. Uden dette vises kun planen.",
    )
    parser.add_argument(
        "--activate",
        action="store_true",
        help="Bed Migadu aktivere domænet efter DNS er slået igennem.",
    )
    parser.add_argument(
        "--diagnose",
        action="store_true",
        help="Vis Migadus DNS-diagnostik.",
    )
    parser.add_argument(
        "--local-part",
        default="mail",
        help="Postkassens lokale del (default: mail).",
    )
    parser.add_argument(
        "--recovery-email",
        default="kristian.n.jensen@gmail.com",
        help="Adresse der modtager Migadu-invitationen.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    migadu_user = pass_value("migadu/account")
    migadu_token = pass_value("migadu/api-key")
    simply_user = pass_value("simply/account")
    simply_token = pass_value("simply/api-key")

    domain = migadu_get(f"/domains/{DOMAIN}", migadu_user, migadu_token, allow_404=True)
    if args.apply:
        domain = ensure_domain(migadu_user, migadu_token)
        ensure_mailbox(
            migadu_user,
            migadu_token,
            args.local_part,
            args.recovery_email,
        )
    elif not domain:
        print(f"==> {DOMAIN} er endnu ikke oprettet hos Migadu")

    if domain:
        required = migadu_dns_records(migadu_user, migadu_token)
        existing = simply_get(simply_user, simply_token)
        preflight_dns(required, existing)
        print(f"==> {len(required)} Migadu-records klar")
        if args.apply:
            apply_dns(required, simply_user, simply_token)

    if args.diagnose:
        diagnostics = migadu_get(
            f"/domains/{DOMAIN}/diagnostics", migadu_user, migadu_token
        )
        print(json.dumps(diagnostics, indent=2, ensure_ascii=False))

    if args.activate:
        result = migadu_get(
            f"/domains/{DOMAIN}/activate", migadu_user, migadu_token
        )
        print(json.dumps(result, indent=2, ensure_ascii=False))

    if not args.apply and not args.diagnose and not args.activate:
        print("==> Tørkørsel færdig. Kør igen med --apply for at ændre noget.")


if __name__ == "__main__":
    main()

