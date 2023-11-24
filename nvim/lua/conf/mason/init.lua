require("mason").setup()
require("mason-lspconfig").setup {
    ensure_installed = {
        "bashls",
        "docker_compose_language_service",
        "golangci_lint_ls",
        "gopls",
        "lua_ls",
        "perlnavigator",
        "rust_analyzer",
        "tsserver",
        "yamlls",
    }
}

