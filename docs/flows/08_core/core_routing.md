# Core — Routing & Navigation Flow

## GoRouter Boot Flow

```mermaid
flowchart TD
    APP[main.dart] --> ROUTER[GoRouter\nlib/core/routing/app_router.dart]
    ROUTER --> REDIRECT{authProvider state?}
    REDIRECT -->|Authenticated| SHELL[ZerpaiShell\nlayout with sidebar]
    REDIRECT -->|Unauthenticated| LOGIN[/login]
    REDIRECT -->|Loading| SPLASH[/splash]

    SHELL --> SIDEBAR[ZerpaiSidebar\n8 nav items]
    SIDEBAR --> CONTENT[Route content area]
```

## Shell Layout

```mermaid
graph LR
    SHELL[ZerpaiShell] --> SIDEBAR[ZerpaiSidebar\n~#2C3E50 dark]
    SHELL --> TOPBAR[Top bar\nbreadcrumbs + user menu]
    SHELL --> CONTENT[Main canvas\nwhite cards on light gray]

    SIDEBAR --> NAV1[Home /]
    SIDEBAR --> NAV2[Items /items]
    SIDEBAR --> NAV3[Inventory /inventory]
    SIDEBAR --> NAV4[Sales /sales]
    SIDEBAR --> NAV5[Accountant /accountant]
    SIDEBAR --> NAV6[Purchases /purchases]
    SIDEBAR --> NAV7[Reports /reports]
    SIDEBAR --> NAV8[Documents /documents]
```

## Route Guard Flow

```mermaid
flowchart TD
    NAV[User navigates to route] --> GUARD[GoRouter redirect callback]
    GUARD --> AUTH{Is authenticated?}
    AUTH -->|no| LOGIN[Redirect to /login]
    AUTH -->|yes| PERM{Has permission?}
    PERM -->|no| HOME[Redirect to /]
    PERM -->|yes| RENDER[Render route page]
```

## Deep Link Handling

```mermaid
flowchart TD
    LINK[Deep link or browser URL] --> ROUTER[GoRouter parses path]
    ROUTER --> PARAMS[Extract :id params]
    PARAMS --> PAGE[Load page with params]
    PAGE --> LOAD[Load entity by ID from API]
    LOAD -->|found| RENDER[Render detail]
    LOAD -->|404| ERR[Error page / redirect to list]
```
