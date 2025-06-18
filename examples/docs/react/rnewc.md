# rnewc — create a React component scaffold

### Synopsis

`rnewc <ComponentName | path/to/ComponentName>`

### Description

Generates:

- `ComponentName.tsx` – basic functional component
- `ComponentName.test.tsx` – RTL smoke test
- `index.ts` barrel export (creates/updates)
- Directory structure if necessary

### Arguments

| Pos | Name / Pattern | Description                                       |
| --: | -------------- | ------------------------------------------------- |
|   1 | name or path   | Either just the component name or a relative path |

### Example

```bash
$ drun rnewc Header/Nav
Component Nav created successfully in Header/Nav
```
