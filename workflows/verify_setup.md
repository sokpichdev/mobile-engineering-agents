# Workflow: Verify Toolkit Setup

Confirms the toolkit is intact after cloning or pulling. Ensures all entry points, core directories,
and expected file counts are present and ready for use in Mode A or Mode B.

## Objective

Confirm that the toolkit has been properly initialized and all critical files and directories exist.

## Inputs

- The current working directory (repo root).

## Outputs

- A pass/fail report with ✓/✗ per check.
- A final health summary: either "Toolkit is healthy — ready for Mode A or Mode B" or
  a list of missing/short items with recovery suggestions.

## Step-by-Step Process

1. **Check entry point files exist** — verify these files are present at the repo root:
   - `CLAUDE.md`
   - `GEMINI.md`
   - `.cursorrules`
   - `.windsurfrules`
   - `AGENTS.md`

2. **Check core directories exist** — verify these directories are present:
   - `agents/`
   - `skills/`
   - `workflows/`
   - `checklists/`
   - `standards/`
   - `templates/`
   - `architecture/`

3. **Check expected file counts** — ensure minimum thresholds are met:
   - `agents/*.md` ≥ 14
   - `skills/**/*.md` ≥ 31
   - `workflows/*.md` ≥ 11
   - `checklists/*.md` ≥ 8
   - `standards/*.md` ≥ 7

4. **Report each check** — display ✓ for pass, ✗ for fail.

5. **Print health summary** — on all pass, print:
   > Toolkit is healthy — ready for Mode A or Mode B

   On any fail, list missing/short items and suggest:
   - Run `git status` to check for missing files
   - Re-clone if the issue persists:
     ```
     git clone https://github.com/sokpichdev/mobile-engineering-agents.git
     ```

## Validation Steps

- Entry point files are readable at the repo root.
- All core directories exist and are accessible.
- File counts meet the specified minimums.

## Failure Scenarios

- **Missing entry point files** → Check recent git pull or clone; some files may not have been fetched.
- **Missing directories** → Incomplete clone or repository structure issue; re-clone or restore from git.
- **File count shortfall** → Files may have been deleted or moved; restore from `git checkout` or re-clone.

## AI Agent Instructions

- Verify by reading directory listings and file counts — no shell commands required.
- Be thorough: check all entry points and all core directories before declaring pass.
- If any single check fails, the overall health is fail; list all failures and suggest recovery steps.
- Do not proceed with Mode A/B guidance if the toolkit is not healthy.

## Acceptance Criteria

- [ ] All five entry point files confirmed present.
- [ ] All seven core directories confirmed present.
- [ ] All file count thresholds met.
- [ ] Health summary printed (pass or fail with guidance).
