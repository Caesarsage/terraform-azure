package modules

import (
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/Caesarsage/terraform-azure/utils"
)

func TestResourceGroup(t *testing.T) {
	t.Parallel()

	utils.SkipIfShort(t)

	err := utils.ValidateRequiredEnvVars()
	require.NoError(t, err, "Required environment variables not set")

	config := utils.GetTestConfig()

	vars := map[string]interface{}{
		"resource_group_name": config.ResourceGroupName,
		"location":            config.Location,
		"tags":                config.Tags,
	}

	terraformOptions := terraform.Options{
		TerraformDir: "./fixtures/resource_group",
		Vars:         vars,
		NoColor:      true,
		RetryableTerraformErrors: map[string]string{
			".*": "Terraform failed due to transient error",
		},
		MaxRetries:         3,
		TimeBetweenRetries: 30 * time.Second,
	}

	defer terraform.Destroy(t, &terraformOptions)

	terraform.InitAndApply(t, &terraformOptions)

	// Validate outputs
	resourceGroupName := terraform.Output(t, &terraformOptions, "name")
	resourceGroupId := terraform.Output(t, &terraformOptions, "id")
	resourceGroupLocation := terraform.Output(t, &terraformOptions, "location")

	// Assertions
	assert.Equal(t, config.ResourceGroupName, resourceGroupName, "Resource group name should match")
	assert.NotEmpty(t, resourceGroupId, "Resource group ID should not be empty")

	expectedLocation := strings.ToLower(strings.ReplaceAll(config.Location, " ", ""))
	assert.Equal(t, expectedLocation, resourceGroupLocation, "Resource group location should match")

	t.Logf("Resource group created successfully: %s", resourceGroupName)
}
