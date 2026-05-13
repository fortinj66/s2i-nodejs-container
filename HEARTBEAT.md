# HEARTBEAT.md - Periodic Task Checks

Run these checks during heartbeat cycles. Rotate through them every 2-4 hours.

## Checklist

- [ ] **Email** — Any urgent unread messages?
- [ ] **Calendar** — Upcoming events in next 24-48h?
- [ ] **Weather** — Relevant if John might go out?
- [ ] **Memory Maintenance** — Review recent daily notes, update MEMORY.md with distilled learnings
- [ ] **System Health** — Git status, workspace changes, any issues

## State Tracking

Track last checks in `memory/heartbeat-state.json`:

```json
{
  "lastChecks": {
    "email": null,
    "calendar": null,
    "weather": null,
    "memory": null,
    "system": null
  }
}
```

## When to Reach Out

- Important email arrived
- Calendar event coming up (<2h)
- Something interesting found
- It's been >8h since last interaction

## When to Stay Quiet (HEARTBEAT_OK)

- Late night (23:00-08:00) unless urgent
- Human is clearly busy
- Nothing new since last check
- Just checked <30 minutes ago

## Related

- [Heartbeat config](/gateway/config-agents)
