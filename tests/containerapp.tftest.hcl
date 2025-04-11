provider "azurerm" {
  features {
  }
}

run "setup_tests" {
  module {
    source = "./tests/setup"
  }

  variables {
    environment = {
      prefix          = "dx"
      env_short       = "d"
      location        = "italynorth"
      domain          = "modules"
      app_name        = "test"
      instance_number = "01"
    }
  }
}

run "container_app_is_correct_plan" {
  command = plan

  variables {
    environment = run.setup_tests.environment

    tags = run.setup_tests.tags

    tier = "xs"

    resource_group_name = run.setup_tests.resource_group_name

    container_app_environment_id = run.setup_tests.container_app_environment_id
    user_assigned_identity_id    = run.setup_tests.user_assigned_identity_id

    container_app_templates = [
      {
        image = "nginx:latest"

        app_settings = {
          "TEST1" = "value1",
          "TEST2" = "value2"
        }

        liveness_probe = {
          path = "/"
        }
      }
    ]

    secrets = [
      {
        name                = run.setup_tests.key_vault_secret1.name
        key_vault_secret_id = run.setup_tests.key_vault_secret1.secret_id
      },
      {
        name                = run.setup_tests.key_vault_secret2.name
        key_vault_secret_id = run.setup_tests.key_vault_secret2.secret_id
      }
    ]
  }

  assert {
    condition     = azurerm_container_app.this.name == "dx-d-itn-modules-test-ca-01"
    error_message = "The container app name is not correct"
  }

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].image == "nginx:latest"
    error_message = "The container app image is not correct"
  }

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].name == "nginx"
    error_message = "The container app container name auto-generated is wrong"
  }

  assert {
    condition = length([
      for env in azurerm_container_app.this.template[0].container[0].env :
      env if env.secret_name == null
    ]) == 2 # number of settings set above
    error_message = "The number of variables in the container app is not correct"
  }

  assert {
    condition = length([
      for env in azurerm_container_app.this.template[0].container[0].env :
      env if env.secret_name != null
    ]) == 2 # number of secrets set above
    error_message = "The number of secrets set as variables in the container app is not correct"
  }

  assert {
    condition     = azurerm_container_app.this.template[0].max_replicas == 1 && azurerm_container_app.this.template[0].min_replicas == 0
    error_message = "The container app replica values are not correct"
  }

  assert {
    condition     = azurerm_container_app.this.template[0].max_replicas == 1 && azurerm_container_app.this.template[0].min_replicas == 0
    error_message = "The container app replica values are not correct"
  }

  assert {
    condition = alltrue([
      for secret in azurerm_container_app.this.secret : secret.name == lower(secret.name)
    ])
    error_message = "The container app secrets names are not correct"
  }

  assert {
    condition = alltrue([
      for secret in azurerm_container_app.this.secret : contains([
        run.setup_tests.key_vault_secret1.secret_id,
        run.setup_tests.key_vault_secret2.secret_id
        ],
      secret.key_vault_secret_id)
    ])
    error_message = "The container app secrets kv references are not correct"
  }

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].liveness_probe[0].path == "/"
    error_message = "The container app liveness probe path is not correct"
  }

  assert {
    condition = alltrue([
      for env in azurerm_container_app.this.template[0].container[0].env : contains([
        "TEST1",
        "TEST2"
        ],
      env.name)
      if env.secret_name == null
    ])
    error_message = "The container app setting names are not correct"
  }

  assert {
    condition = alltrue([
      for env in azurerm_container_app.this.template[0].container[0].env : contains([
        "value1",
        "value2"
        ],
      env.value)
      if env.secret_name == null
    ])
    error_message = "The container app setting values are not correct"
  }

  assert {
    condition = alltrue([
      for env in azurerm_container_app.this.template[0].container[0].env : contains([
        run.setup_tests.key_vault_secret1.name,
        run.setup_tests.key_vault_secret2.name,
        ],
      env.name)
      if env.secret_name != null
    ])
    error_message = "The container app environment secret names are not correct"
  }

  assert {
    condition = alltrue([
      for env in azurerm_container_app.this.template[0].container[0].env : contains([
        replace(lower(run.setup_tests.key_vault_secret1.name), "_", "-"),
        replace(lower(run.setup_tests.key_vault_secret2.name), "_", "-"),
        ],
      env.secret_name)
      if env.secret_name != null
    ])
    error_message = "The container app environment secret values are not correct"
  }
}

run "container_app_correct_container_name" {
  command = plan

  variables {
    environment = run.setup_tests.environment

    tags = run.setup_tests.tags

    tier = "xs"

    resource_group_name = run.setup_tests.resource_group_name

    container_app_environment_id = run.setup_tests.container_app_environment_id
    user_assigned_identity_id    = run.setup_tests.user_assigned_identity_id

    container_app_templates = [
      {
        image = "ghcr.io/pagopa/selfcare-dashboard-backend:sha-4b7f62d"

        liveness_probe = {
          path = "/"
        }
      }
    ]
  }

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].image == "ghcr.io/pagopa/selfcare-dashboard-backend:sha-4b7f62d"
    error_message = "The container app image is not correct"
  }

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].name == "selfcare-dashboard-backend"
    error_message = "The container app container name auto-generated is wrong"
  }
}

run "container_app_correct_custom_container_name" {
  command = plan

  variables {
    environment = run.setup_tests.environment

    tags = run.setup_tests.tags

    tier = "xs"

    resource_group_name = run.setup_tests.resource_group_name

    container_app_environment_id = run.setup_tests.container_app_environment_id
    user_assigned_identity_id    = run.setup_tests.user_assigned_identity_id

    container_app_templates = [
      {
        image = "nginx:latest"
        name  = "custom-nginx"

        liveness_probe = {
          path = "/"
        }
      }
    ]
  }

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].image == "nginx:latest"
    error_message = "The container app image is not correct"
  }

  assert {
    condition     = azurerm_container_app.this.template[0].container[0].name == "custom-nginx"
    error_message = "The container app container name auto-generated is wrong"
  }
}
