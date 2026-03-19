// naming.bicep
// CAF-aligned naming helper functions for consistent, globally-unique resource names.
//
// Description:
//   Exports four naming functions covering the full range of Azure naming constraints.
//   Choose the function based on the uniqueness scope and character restrictions of the
//   target resource type:
//
//   longName     — DNS-globally unique, hyphens allowed, hash suffix appended
//                  Pattern: <prefix>-<project>-<env>-<region>-<hash6>    (≤60 chars)
//   shortName    — DNS-globally unique, hyphens allowed, strict length limit (Key Vault etc.)
//                  Pattern: <prefix>-<proj4>-<env3>-<hash10>             (≤24 chars)
//   alphanumName — DNS-globally unique, no hyphens, strict length limit (ACR, Storage etc.)
//                  Pattern: <prefix><proj5><env3><hash14>                (≤24 chars)
//   simpleName   — Scope-unique only (resource group or parent resource), no hash needed
//                  Pattern: <prefix>-<project>-<env>-<region>            (≤60 chars)
//
// Usage:
//   import { longName, shortName, alphanumName, simpleName } from './naming.bicep'

@export()
func longName(prefix string, project string, env string, regionAbbr string, nameHash string) string =>
  '${prefix}-${project}-${env}-${regionAbbr}-${take(nameHash, 6)}'

@export()
func shortName(prefix string, project string, env string, nameHash string) string =>
  '${prefix}-${take(project, 4)}-${take(env, 3)}-${take(nameHash, 10)}'

@export()
func alphanumName(prefix string, project string, env string, nameHash string) string =>
  '${prefix}${take(project, 5)}${take(env, 3)}${take(nameHash, 14)}'

@export()
func simpleName(prefix string, project string, env string, regionAbbr string) string =>
  '${prefix}-${project}-${env}-${regionAbbr}'
