package modules

import (
	"testing"
	"time"

	"github.com/Caesarsage/terraform-azure/utils"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestNatGateway(t *testing.T) {
	t.Parallel()

	utils.SkipIfShort(t)

	err := utils.ValidateRequiredEnvVars()
	require.NoError(t, err, "Required environment variables not set")

	config := utils.GetTestConfig()

	// Generate names for resources used by this test
	natGatewayName := utils.GenerateUniqueName("nat-gateway")
	pipName := utils.GenerateUniqueName("pip")

	vars := map[string]interface{}{
		"resource_group_name":      config.ResourceGroupName,
		"location":                 config.Location,
		"nat_gateway_name":         natGatewayName,
		"public_ip_name":           pipName,
		"tags":                     config.Tags,
	}

	terraformOptions := terraform.Options{
		TerraformDir: "./fixtures/nat_gateway",
		Vars:         vars,
		NoColor:      true,
		RetryableTerraformErrors: map[string]string{
			".*": "Terraform failed due to transient error",
		},
		MaxRetries:         6,
		TimeBetweenRetries: 60 * time.Second,
	}

	// Defer destroy with simple retries to handle transient Azure deletion issues.
	defer func() {
		var lastErr error
		for i := 0; i < 6; i++ {
			_, err := terraform.DestroyE(t, &terraformOptions)
			if err == nil {
				lastErr = nil
				break
			}
			lastErr = err
			t.Logf("terraform destroy attempt %d failed: %v", i+1, err)
			time.Sleep(30 * time.Second)
		}
		if lastErr != nil {
			t.Logf("terraform destroy failed after retries: %v", lastErr)
		}
	}()

	terraform.InitAndApply(t, &terraformOptions)

	// Validate outputs (ensure id and public ip id are present)
	natGatewayId := terraform.Output(t, &terraformOptions, "nat_gateway_id")
	publicIpId := terraform.Output(t, &terraformOptions, "public_ip_id")

	assert.NotEmpty(t, natGatewayId, "NAT Gateway ID should not be empty")
	assert.NotEmpty(t, publicIpId, "Public IP ID should not be empty")

	t.Logf("NAT Gateway created successfully: %s", natGatewayId)
}
