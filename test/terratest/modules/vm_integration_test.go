package modules

import (
	"testing"
	"time"

	"github.com/Caesarsage/terraform-azure/utils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)


func TestVMIntegration(t *testing.T) {
	t.Parallel()

	utils.SkipIfShort(t)

	err := utils.ValidateRequiredEnvVars()
	require.NoError(t, err)

	config := utils.GetTestConfig()
	vmName := utils.GenerateUniqueName("test-vm")
	vnetName := utils.GenerateUniqueName("test-vnet")

	vars := map[string]interface{}{
		"resource_group_name": config.ResourceGroupName,
		"location":            config.Location,
		"vm_name":             vmName,
		"vnet_name":           vnetName,
		"vm_size":             "Standard_B1s",
		"admin_username":      "azureuser",
		"create_public_ip":    false,
		"attach_nsg":          true,
		"create_data_disk":    false,
		"tags":                config.Tags,
	}

	terraformOptions := &terraform.Options{
		TerraformDir: "./fixtures/vm_integration",
		Vars:         vars,
		NoColor:      true,
		RetryableTerraformErrors: map[string]string{
			".*": "Terraform failed due to transient error",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 30 * time.Second,
	}

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	vnetId := terraform.Output(t, terraformOptions, "vnet_id")
	vmIds := terraform.OutputList(t, terraformOptions, "vm_ids")

	assert.NotEmpty(t, vnetId)
	assert.Len(t, vmIds, 1)

	t.Logf("Integration test completed - VNet: %s, VM: %s", vnetId, vmIds[0])
}
