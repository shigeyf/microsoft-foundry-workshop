// regions.bicep
// Comprehensive Azure region-to-abbreviation map for CAF-aligned resource naming.
//
// Description:
//   Exports a single string-keyed object mapping every Azure public cloud region
//   identifier to a short abbreviation used in resource names. Sovereign clouds
//   (US Government, China) are not included. Regions marked "coming soon" are
//   included for forward compatibility.
//
// Usage:
//   import { regionAbbreviations } from './regions.bicep'
//   var regionAbbr = regionAbbreviations[?location] ?? take(location, 4)
//
// Notes:
//   Source:   https://learn.microsoft.com/en-us/azure/reliability/regions-list
//   Coverage: all Azure public cloud regions as of 2026-03.

@export()
var regionAbbreviations = {
  // --- Asia Pacific ---
  australiacentral: 'auc' // Australia Central   (Canberra, restricted)
  australiacentral2: 'auc2' // Australia Central 2 (Canberra, restricted)
  australiaeast: 'aue' // Australia East      (New South Wales)
  australiasoutheast: 'ause' // Australia Southeast (Victoria)
  centralindia: 'cin' // Central India       (Pune)
  eastasia: 'ea' // East Asia           (Hong Kong SAR)
  indonesiacentral: 'idc' // Indonesia Central   (Jakarta)
  japaneast: 'jpe' // Japan East          (Tokyo, Saitama)
  japanwest: 'jpw' // Japan West          (Osaka)
  koreacentral: 'krc' // Korea Central       (Seoul)
  koreasouth: 'krs' // Korea South         (Busan)
  malaysiawest: 'myw' // Malaysia West       (Kuala Lumpur)
  newzealandnorth: 'nzn' // New Zealand North   (Auckland)
  southeastasia: 'sea' // Southeast Asia      (Singapore)
  southindia: 'sin' // South India         (Chennai)
  westindia: 'win' // West India          (Mumbai)
  // --- Americas ---
  brazilsouth: 'brs' // Brazil South        (Sao Paulo State)
  brazilsoutheast: 'brse' // Brazil Southeast    (Rio, restricted)
  canadacentral: 'cnc' // Canada Central      (Toronto)
  canadaeast: 'cne' // Canada East         (Quebec)
  centralus: 'cus' // Central US          (Iowa)
  chilecentral: 'clc' // Chile Central       (Santiago)
  eastus: 'eus' // East US             (Virginia)
  eastus2: 'eus2' // East US 2           (Virginia)
  mexicocentral: 'mxc' // Mexico Central      (Querétaro State)
  northcentralus: 'ncus' // North Central US    (Illinois)
  southcentralus: 'scus' // South Central US    (Texas)
  westcentralus: 'wcus' // West Central US     (Wyoming)
  westus: 'wus' // West US             (California)
  westus2: 'wus2' // West US 2           (Washington)
  westus3: 'wus3' // West US 3           (Phoenix)
  // --- Europe ---
  austriaeast: 'ate' // Austria East        (Vienna)
  belgiumcentral: 'bec' // Belgium Central     (Brussels)
  denmarkeast: 'dke' // Denmark East        (Copenhagen, coming soon)
  francecentral: 'frc' // France Central      (Paris)
  francesouth: 'frs' // France South        (Marseille, restricted)
  germanynorth: 'gyn' // Germany North       (Berlin, restricted)
  germanywestcentral: 'gwc' // Germany West Central (Frankfurt)
  italynorth: 'itn' // Italy North         (Milan)
  northeurope: 'neu' // North Europe        (Ireland)
  norwayeast: 'noe' // Norway East         (Norway)
  norwaywest: 'now' // Norway West         (Norway, restricted)
  polandcentral: 'plc' // Poland Central      (Warsaw)
  spaincentral: 'spc' // Spain Central       (Madrid)
  swedencentral: 'swc' // Sweden Central      (Gävle)
  switzerlandnorth: 'swn' // Switzerland North   (Zurich)
  switzerlandwest: 'sww' // Switzerland West    (Geneva, restricted)
  uksouth: 'uks' // UK South            (London)
  ukwest: 'ukw' // UK West             (Cardiff)
  westeurope: 'weu' // West Europe         (Netherlands)
  // --- Middle East ---
  israelcentral: 'ilc' // Israel Central      (Israel)
  qatarcentral: 'qtc' // Qatar Central       (Doha)
  uaecentral: 'uac' // UAE Central         (Abu Dhabi, restricted)
  uaenorth: 'uan' // UAE North           (Dubai)
  // --- Africa ---
  southafricanorth: 'san' // South Africa North  (Johannesburg)
  southafricawest: 'saw' // South Africa West   (Cape Town, restricted)
}
