package modules

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/Caesarsage/terraform-azure/utils"
)

func TestRedis(t *testing.T) {
	t.Parallel()

	utils.SkipIfShort(t)

	err := utils.ValidateRequiredEnvVars()
	require.NoError(t, err, "Required environment variables not set")

	config := utils.GetTestConfig()

	// Generate unique name for Redis
	rName := utils.GenerateUniqueName("redis")

	vars := map[string]interface{}{
		"redis_name":          rName,
		"resource_group_name": config.ResourceGroupName,
		"location":            config.Location,
		"tags":                config.Tags,
	}

	terraformOptions := terraform.Options{
		TerraformDir:       "./fixtures/redis",
		Vars:               vars,
		NoColor:            true,
		MaxRetries:         3,
		TimeBetweenRetries: 30 * time.Second,
	}

	defer func() {
		// Best-effort cleanup
		_, _ = terraform.DestroyE(t, &terraformOptions)
	}()

	terraform.InitAndApply(t, &terraformOptions)

	redisId := terraform.Output(t, &terraformOptions, "redis_id")
	assert.NotEmpty(t, redisId, "Redis ID should not be empty")

	t.Logf("Redis created: %s", redisId)
}
