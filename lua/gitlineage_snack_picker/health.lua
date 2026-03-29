local M = {}

local health = vim.health

M.check = function()
	health.start("gitlineage-snack_picker.nvim")

	-- Check Neovim version
	if vim.fn.has("nvim-0.7.0") == 1 then
		health.ok("Neovim >= 0.7.0")
	else
		health.error("Neovim >= 0.7.0 required")
	end

	-- Check git is available
	local git_version = vim.fn.systemlist({ "git", "--version" })
	if vim.v.shell_error == 0 and git_version[1] then
		health.ok("git found: " .. git_version[1])
	else
		health.error("git not found in PATH")
	end

	-- Check if current directory is a git repo
	local in_repo = vim.fn.systemlist({ "git", "rev-parse", "--is-inside-work-tree" })
	if vim.v.shell_error == 0 and in_repo[1] == "true" then
		health.ok("Current directory is a git repository")
	else
		health.info("Current directory is not a git repository (gitlineage only works in git repos)")
	end

	-- Check snacks.nvim
	local has_snacks, _ = pcall(require, "snacks")
	if has_snacks then
		health.ok("snacks.nvim found (required for picker)")
	else
		health.error("snacks.nvim not found (required)")
		health.info("  Install from: https://github.com/folke/snacks.nvim")
	end

	-- Check optional dependency: diffview.nvim
	local has_diffview, _ = pcall(require, "diffview")
	if has_diffview then
		health.ok("diffview.nvim found (Ctrl-D in picker to open diff)")
	else
		health.info("diffview.nvim not found (Ctrl-D action disabled)")
		health.info("  Install from: https://github.com/sindrets/diffview.nvim")
	end

	-- Check configuration
	local ok, gitlineage = pcall(require, "gitlineage_snack_picker")
	if ok then
		health.ok("gitlineage_snack_picker loaded")
		health.info("keymap: " .. (gitlineage.config.keymap or "disabled"))
	else
		health.error("Failed to load gitlineage_snack_picker module")
	end
end

return M
