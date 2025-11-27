package utils

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/alecthomas/assert"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

// TestConfig holds common test configuration
type TestConfig struct {
	ResourceGroupName string
	Location          string
	Environment       string
	Tags              map[string]string
}

// GetTestConfig returns a standardized test configuration
func GetTestConfig() *TestConfig {
	return &TestConfig{
		ResourceGroupName: getTestResourceGroupName(),
		Location:          getTestLocation(),
		Environment:       "Test",
		Tags: map[string]string{
			"Environment": "Test",
			"Project":     "TerraformModules",
			"Test":        "true",
			"CreatedBy":   "Terratest",
		},

	}
}

// getTestResourceGroupName generates a unique resource group name for testing
func getTestResourceGroupName() string {
	baseName := os.Getenv("TEST_RESOURCE_GROUP_NAME")
	if baseName == "" {
		baseName = "rg-tests"
	}

	return baseName
}

// getTestLocation returns the Azure location for testing
func getTestLocation() string {
	location := os.Getenv("TEST_LOCATION")
	if location == "" {
		location = "West Europe"
	}
	return location
}

func GenerateUniqueName(prefix string) string {
	suffix := random.UniqueId()
	return fmt.Sprintf("%s-%s", prefix, suffix)
}

// GetTerraformOptions creates standardized Terraform options for testing
func GetTerraformOptions(terraformDir string, vars map[string]interface{}) *terraform.Options {
	config := GetTestConfig()

	// Merge provided vars with default config
	mergedVars := map[string]interface{}{
		"resource_group_name": config.ResourceGroupName,
		"location":            config.Location,
		"tags":                config.Tags,
	}

	for key, value := range vars {
		mergedVars[key] = value
	}

	return &terraform.Options{
		TerraformDir: terraformDir,
		Vars:         mergedVars,
		NoColor:      true,
	}
}

// GetTerraformOptionsWithBackend creates Terraform options with backend configuration
func GetTerraformOptionsWithBackend(terraformDir string, vars map[string]interface{}) *terraform.Options {
	options := GetTerraformOptions(terraformDir, vars)
	config := GetTestConfig()

	// Add backend configuration for testing
	options.BackendConfig = map[string]interface{}{
		"resource_group_name":  config.ResourceGroupName,
		"storage_account_name": getTestStorageAccountName(),
		"container_name":       "tfstate",
		"key":                  fmt.Sprintf("test-%s.tfstate", random.UniqueId()),
	}

	return options
}

// getTestStorageAccountName generates a unique storage account name
func getTestStorageAccountName() string {
	baseName := "teststg"
	suffix := random.UniqueId()

	// Storage account names must be 3-24 characters, lowercase, alphanumeric
	fullName := fmt.Sprintf("%s%s", baseName, suffix)
	if len(fullName) > 24 {
		fullName = fullName[:24]
	}

	return strings.ToLower(fullName)
}

// CleanupTestResources cleans up test resources
func CleanupTestResources(t *testing.T, options *terraform.Options) {
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("Error during cleanup: %v\n", r)
		}
	}()

	terraform.Destroy(t, options)
}

// GetRandomName generates a random name for testing
func GetRandomName(prefix string) string {
	suffix := random.UniqueId()
	return fmt.Sprintf("%s-%s", prefix, suffix)
}

// ValidateRequiredEnvVars checks for required environment variables
func ValidateRequiredEnvVars() error {
	requiredVars := []string{
		"ARM_CLIENT_ID",
		"ARM_CLIENT_SECRET",
		"ARM_SUBSCRIPTION_ID",
		"ARM_TENANT_ID",
	}

	for _, varName := range requiredVars {
		if os.Getenv(varName) == "" {
			return fmt.Errorf("required environment variable %s is not set", varName)
		}
	}

	return nil
}

// GetTestTimeout returns appropriate timeout for tests
func GetTestTimeout() time.Duration {
	timeoutStr := os.Getenv("TEST_TIMEOUT")
	if timeoutStr != "" {
		if timeout, err := time.ParseDuration(timeoutStr); err == nil {
			return timeout
		}
	}

	// Default timeout
	return 30 * time.Minute
}

// GetTestParallelism returns the number of parallel tests to run
func GetTestParallelism() int {
	parallelStr := os.Getenv("TEST_PARALLELISM")
	if parallelStr != "" {
		if parallel, err := strconv.Atoi(parallelStr); err == nil && parallel > 0 {
			return parallel
		}
	}

	// Default parallelism
	return 1
}

// GenerateTestTags creates standardized tags for test resources
func GenerateTestTags(testName string) map[string]string {
	return map[string]string{
		"Environment": "Test",
		"Project":     "TerraformModules",
		"Test":        "true",
		"TestName":    testName,
		"CreatedBy":   "Terratest",
		"CreatedAt":   time.Now().Format(time.RFC3339),
	}
}

// RetryConfig provides retry configuration for tests
type RetryConfig struct {
	MaxRetries         int
	TimeBetweenRetries time.Duration
}

// GetDefaultRetryConfig returns default retry configuration
func GetDefaultRetryConfig() *RetryConfig {
	return &RetryConfig{
		MaxRetries:         3,
		TimeBetweenRetries: 30 * time.Second,
	}
}

// WaitForResource waits for a resource to be in the expected state
func WaitForResource(resourceName string, expectedState string, timeout time.Duration) error {
	// Implementation would depend on the specific resource type
	// This is a placeholder for resource state validation
	return nil
}

// ValidateOutputs validates that all expected outputs are present and have expected values
func ValidateOutputs(t *testing.T, options *terraform.Options, expectedOutputs map[string]interface{}) {
	for outputName, expectedValue := range expectedOutputs {
		actualValue := terraform.Output(t, options, outputName)

		if expectedValue != nil {
			assert.Equal(t, expectedValue, actualValue,
				"Output %s should equal %v, but got %v", outputName, expectedValue, actualValue)
		} else {
			assert.NotEmpty(t, actualValue, "Output %s should not be empty", outputName)
		}
	}
}

// SkipIfNotCI skips the test if not running in CI environment
func SkipIfNotCI(t *testing.T) {
	if os.Getenv("CI") == "" {
		t.Skip("Skipping test - not running in CI environment")
	}
}

// SkipIfShort skips the test if running in short mode
func SkipIfShort(t *testing.T) {
	if testing.Short() {
		t.Skip("Skipping test - running in short mode")
	}
}
