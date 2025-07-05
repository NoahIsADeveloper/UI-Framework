# Contributing to [Your Roblox Game]

Thanks for your interest in contributing! To keep our codebase clean, consistent, and awesome, please follow these guidelines.

## Coding Style

- **Global variables:** Use **PascalCase**  
  ```lua
  local Module = {}
  local RunService = game:GetService("RunService")
  ```
- **Local variables:** Use **camelCase**  
  ```lua
  local index = 1
  local currentValue = 42
  ```
- **Avoid acronyms:** Use full service names, not abbreviations  
  Examples: `UserInputService` instead of `USI`, `RunService` over `RS`, ect.

- **Descriptive names:** Name your variables and functions clearly  
  Examples: `value`, `index`, `clone`, `bfr` (buffer is taken), `LocalPlayer`, ect.

- **Module variables:** Prefix with an underscore `_`  
  ```lua
  local Module = {
	_health = 100,
	_defense = 30,
  }
  ```

- **Tabs, not spaces:** Indent your code with tabs (`\t`), not spaces (    ).

## Folder Metadata

Each folder should have an `init.meta.json` to set its name.  
Check the `Folders` in `shared/` for examples.

## Type Annotations

Use type annotations wherever possible to improve code safety and readability.  
Please fix or add type annotations in your changes.

Example:

```lua
local function add(a: number, b: number): number
    return a + b
end
```

## Pull Requests

- Fork the repo and create your feature branch from `dev`.
- Write clear, descriptive commit messages.
- Test your changes thoroughly.
- Include updates to type annotations if your changes affect types.
- Submit a pull request against the `dev` branch.
- Explain the purpose of your change and any relevant context in the PR description.