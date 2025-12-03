package modules

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/Caesarsage/terraform-azure/utils"
)

func TestRouteTable(t *testing.T) {
	t.Parallel()

	utils.SkipIfShort(t)

	err := utils.ValidateRequiredEnvVars()
	require.NoError(t, err, "Required environment variables not set")

	config := utils.GetTestConfig()

	rt_name := utils.GenerateUniqueName("test-rt")

	vars := map[string]interface{}{
		"route_table_name": rt_name,
		"location":         config.Location,
		"tags":             config.Tags,
	}

	terraformOptions := terraform.Options{
		TerraformDir: "./fixtures/route_table",
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
	routeTableId := terraform.Output(t, &terraformOptions, "route_table_id")
	assert.NotEmpty(t, routeTableId, "Route table ID should not be empty")


	t.Logf("Route table created successfully: %s", rt_name)
}
