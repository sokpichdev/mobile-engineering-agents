# Examples

Reference architectures showing how the toolkit's agents, skills, standards, and workflows
combine on real product shapes. Each demonstrates Clean Architecture, API integration,
authentication, DI, error handling, a testing strategy, and scalability — with a Mermaid module
diagram and key illustrative snippets.

- [banking_app/](banking_app/) — security-first: OAuth2/PKCE, Keychain, TLS pinning, idempotent transfers
- [chat_app/](chat_app/) — realtime + offline: WebSocket actor, optimistic sends, sync
- [ecommerce_app/](ecommerce_app/) — catalog + cart + checkout: pagination, caching, idempotent payment
- [social_media_app/](social_media_app/) — feed-centric: infinite scroll, media performance, realtime interactions

Each example links to the [workflows](../workflows/) you'd follow to build it.
