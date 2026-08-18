export type BumpType = "major" | "minor" | "patch";

/**
 * The release bump a branch asks for, from its prefix alone.
 * `null` for any prefix that must not release.
 */
export function bumpTypeFromBranch(branchName: unknown): BumpType | null {
  if (typeof branchName !== "string") return null;
  if (branchName.startsWith("fix/")) return "patch";
  if (branchName.startsWith("feat/")) return "minor";
  if (branchName.startsWith("release/")) return "major";
  return null;
}

const SEMVER_PATTERN = /^(\d+)\.(\d+)\.(\d+)$/;

/**
 * `null` for a malformed version or a null bump type — callers treat that as
 * "no release", never as an error to recover from.
 */
export function bumpVersion(
  currentVersion: unknown,
  bumpType: BumpType | null,
): string | null {
  if (typeof currentVersion !== "string") return null;
  const match = SEMVER_PATTERN.exec(currentVersion);
  if (!match) return null;
  const [, majorRaw, minorRaw, patchRaw] = match;
  const major = Number(majorRaw);
  const minor = Number(minorRaw);
  const patch = Number(patchRaw);
  if (!Number.isSafeInteger(major) || !Number.isSafeInteger(minor) || !Number.isSafeInteger(patch)) {
    return null;
  }
  if (major < 0 || minor < 0 || patch < 0) return null;
  if (bumpType === "patch") return `${major}.${minor}.${patch + 1}`;
  if (bumpType === "minor") return `${major}.${minor + 1}.0`;
  if (bumpType === "major") return `${major + 1}.0.0`;
  return null;
}
