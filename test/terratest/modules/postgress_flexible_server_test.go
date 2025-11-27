package modules

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/Caesarsage/terraform-azure/utils"
)

func TestPostgresFlexibleServer(t *testing.T) {
	t.Parallel()

	utils.SkipIfShort(t)

	err := utils.ValidateRequiredEnvVars()
	require.NoError(t, err, "Required environment variables not set")

	config := utils.GetTestConfig()

	// Generate unique name for PostgreSQL Flexible Server
	pgName := utils.GenerateUniqueName("postgresql-flexible")
	pgLogin := utils.GenerateUniqueName("psqladminun")
	pgPassword := "H@Sh1CoR3!"

	vars := map[string]interface{}{
		"postgresql_flexible_name": pgName,
		"administrator_login":      pgLogin,
		"administrator_password":   pgPassword,
		"resource_group_name":      config.ResourceGroupName,
		"location":                 config.Location,
		"tags":                     config.Tags,
	}

	terraformOptions := terraform.Options{
		TerraformDir:       "./fixtures/postgres_flexible_server",
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

	serverId := terraform.Output(t, &terraformOptions, "server_id")
	assert.NotEmpty(t, serverId, "Server ID should not be empty")

	t.Logf("PostgreSQL Flexible Server created: %s", serverId)
}
