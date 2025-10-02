package modules

import (
	"testing"
	"time"

	"github.com/Caesarsage/terraform-azure/utils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNetworkingModule(t *testing.T) {
	t.Parallel()

	utils.SkipIfShort(t)

	err := utils.ValidateRequiredEnvVars()
	require.NoError(t, err, "Required environment variables not set")

	config := utils.GetTestConfig()
	uniqueName := utils.GenerateUniqueName("test-vnet")

	vars := map[string]interface{}{
		"resource_group_name": config.ResourceGroupName,
		"location":            config.Location,
		"vnet_name":           uniqueName,
		"tags":                config.Tags,
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "./fixtures/networking",
		Vars:         vars,
		NoColor:      true,
		RetryableTerraformErrors: map[string]string{
			".*": "Terraform failed due to transient error",
		},
		MaxRetries:         2,
		TimeBetweenRetries: 30 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Get outputs - use correct output names
	vnetId := terraform.Output(t, terraformOptions, "vnet_id")
	vnetName := terraform.Output(t, terraformOptions, "vnet_name")

	// For map outputs, use OutputMapOfObjects or parse JSON
	subnetIdsJson := terraform.OutputJson(t, terraformOptions, "subnet_ids")
	nsgIdsJson := terraform.OutputJson(t, terraformOptions, "nsg_ids")

	// Assertions
	assert.NotEmpty(t, vnetId, "VNet ID should not be empty")
	assert.Equal(t, uniqueName, vnetName, "VNet name should match")
	assert.Contains(t, vnetId, "/virtualNetworks/", "VNet ID should be valid")
	assert.Contains(t, vnetId, uniqueName, "VNet ID should contain VNet name")

	// Validate subnet and NSG maps are not empty
	assert.NotEmpty(t, subnetIdsJson, "Subnet IDs should not be empty")
	assert.NotEmpty(t, nsgIdsJson, "NSG IDs should not be empty")

	t.Logf("Networking test completed successfully")
	t.Logf("VNet Name: %s", vnetName)
	t.Logf("VNet ID: %s", vnetId)
}
