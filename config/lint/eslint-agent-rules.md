# ESLint Agent Remediation Rules

When flagging or encountering these lint errors, include the concrete fix in your output. These are the most common errors agents encounter.

## TypeScript

| Rule | Fix |
|------|-----|
| `no-explicit-any` | Use a specific type, generic, or `unknown`. Never `as any`. If the type is truly unknowable, use `unknown` and narrow with a type guard. |
| `no-unused-vars` | Remove the import/variable. If it's intentionally unused (e.g., rest destructuring), prefix with `_`. |
| `prefer-const` | Change `let` to `const` if the variable is never reassigned. |
| `no-non-null-assertion` | Use optional chaining (`?.`) or a null check instead of `!`. |
| `consistent-type-imports` | Use `import type { Foo }` for type-only imports. |

## React / Next.js

| Rule | Fix |
|------|-----|
| `react/no-unescaped-entities` | Use `&apos;` for `'`, `&quot;` for `"`, `&amp;` for `&` in JSX text. |
| `react-hooks/exhaustive-deps` | Add missing deps to the array. If intentionally excluded, add a comment explaining why. Never disable the rule. |
| `react-hooks/rules-of-hooks` | Hooks must be called at the top level of a component or custom hook. Never inside conditions, loops, or callbacks. |
| `@next/next/no-img-element` | Use `next/image` `<Image>` component instead of `<img>`. |
| `@next/next/no-html-link-for-pages` | Use `next/link` `<Link>` component instead of `<a>` for internal navigation. |

## Tailwind

| Rule | Fix |
|------|-----|
| Hardcoded color in className | Replace with design token: `text-gray-900` → `text-foreground`, `bg-gray-100` → `bg-secondary`. |
| Hardcoded spacing off rhythm | Use the project's spacing scale (multiples of 4): `py-7` → `py-8`, `mt-5` → `mt-4` or `mt-6`. |
| Conflicting utilities | Remove the lower-specificity class. `p-4 px-6` → `px-6 py-4`. |
