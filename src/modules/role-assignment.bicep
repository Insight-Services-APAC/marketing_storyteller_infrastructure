// ============================================================================
// Role Assignment Module
// ============================================================================
// Creates a role assignment for a principal (user, group, or service principal)
// This module must be deployed at the same scope as the target resource
// ============================================================================

@description('The principal ID (object ID) to assign the role to')
param principalId string

@description('The principal type (User, Group, ServicePrincipal, etc.)')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
  'ForeignGroup'
  'Device'
])
param principalType string = 'ServicePrincipal'

@description('The role definition ID (GUID) to assign')
param roleDefinitionId string

@description('The name of the target resource')
param targetResourceName string

@description('The type of the target resource')
param targetResourceType string

@description('Optional description for the role assignment')
param description string = ''

// ============================================================================
// Reference to Target Resource
// ============================================================================

// Note: We use 'existing' to reference the resource in the same scope
// The actual role assignment will be created on this resource

// ============================================================================
// Role Assignment Resource
// ============================================================================

// Role assignment uses a deterministic GUID based on scope, principal, and role
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(targetResourceName, principalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
    description: description
  }
}

// ============================================================================
// Outputs
// ============================================================================

output roleAssignmentId string = roleAssignment.id
output roleAssignmentName string = roleAssignment.name
output principalId string = principalId
output roleDefinitionId string = roleDefinitionId
