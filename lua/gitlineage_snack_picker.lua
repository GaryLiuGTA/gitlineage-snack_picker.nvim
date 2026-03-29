local linemap = require("gitlineage_snack_picker.linemap")

local M = {}

M.config = {
	keymap = "<leader>gh",
}

local function is_git_repo()
	local result = vim.fn.systemlist({ "git", "rev-parse", "--is-inside-work-tree" })
	return vim.v.shell_error == 0 and result[1] == "true"
end

local function is_file_tracked(file)
	vim.fn.systemlist({ "git", "ls-files", "--error-unmatch", file })
	return vim.v.shell_error == 0
end

function M.pick(opts)
	opts = opts or {}

	if not is_git_repo() then
		vim.notify("gitlineage-snack_picker: not inside a git repository", vim.log.levels.WARN)
		return
	end

	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("gitlineage-snack_picker: buffer has no file", vim.log.levels.WARN)
		return
	end

	local git_root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
	if vim.v.shell_error ~= 0 then
		vim.notify("gitlineage-snack_picker: failed to get git root", vim.log.levels.WARN)
		return
	end

	local rel_file = file:sub(#git_root + 2)
	if rel_file == "" then
		rel_file = vim.fn.expand("%")
	end

	if not is_file_tracked(rel_file) then
		vim.notify("gitlineage-snack_picker: file is not tracked by git", vim.log.levels.WARN)
		return
	end

	local l1, l2

	if opts.line1 and opts.line2 then
		l1 = opts.line1
		l2 = opts.line2
	else
		local vstart = vim.fn.getpos("'<")
		local vend = vim.fn.getpos("'>")
		if vstart[2] > 0 and vend[2] > 0 and vstart[2] ~= vend[2] then
			l1 = vstart[2]
			l2 = vend[2]
		else
			local cur = vim.fn.line(".")
			l1 = cur
			l2 = cur
		end
	end

	if l1 > l2 then
		l1, l2 = l2, l1
	end

	if l1 < 1 or l2 < 1 then
		vim.notify("gitlineage-snack_picker: invalid line selection", vim.log.levels.WARN)
		return
	end

	if vim.bo.modified then
		local choice = vim.fn.confirm(
			"gitlineage: buffer has unsaved changes. Save before continuing?",
			"&Save\n&Continue (results may drift)\n&Abort"
		)
		if choice == 1 then
			vim.cmd("silent write")
		elseif choice == 3 or choice == 0 then
			return
		end
	end

	local mapping = linemap.map_lines_to_head(git_root, rel_file, l1, l2)

	if mapping.all_new then
		local msg = l1 == l2 and "selected line is an uncommitted addition (no history)"
			or "all selected lines are uncommitted additions (no history)"
		vim.notify("gitlineage-snack_picker: " .. msg, vim.log.levels.INFO)
		return
	end

	local range_str = mapping.l1 .. "," .. mapping.l2 .. ":" .. rel_file
	local title = "Git Line History L" .. l1 .. "-" .. l2

	if #mapping.new_lines > 0 then
		local word = #mapping.new_lines == 1 and "Line" or "Lines"
		vim.notify(
			"gitlineage: " .. word .. " " .. table.concat(mapping.new_lines, ", ") .. " are uncommitted additions (no history)",
			vim.log.levels.INFO
		)
	end

	Snacks.picker.pick({
		title = title,
		finder = function(_, ctx)
			local args = {
				"-c", "core.quotepath=false",
				"log",
				"--pretty=format:%h %s (%ch) <%an>",
				"--abbrev-commit",
				"--date=short",
				"--color=never",
				"--no-show-signature",
				"--no-patch",
				"-L", range_str,
			}
			return require("snacks.picker.source.proc").proc(ctx:opts({
				cmd = "git",
				args = args,
				cwd = git_root,
				---@param item snacks.picker.finder.Item
				transform = function(item)
					local commit, msg, date, author = item.text:match("^(%S+) (.*) %((.*)%) <(.*)>$")
					if not commit then
						return false
					end
					item.cwd = git_root
					item.commit = commit
					item.msg = msg
					item.date = date
					item.author = author
					item.file = rel_file
				end,
			}), ctx)
		end,
		format = "git_log",
		preview = "git_show",
		sort = { fields = { "score:desc", "idx" } },
		actions = {
			yank_commit = function(_, item)
				if item and item.commit then
					vim.fn.setreg("+", item.commit)
					vim.fn.setreg('"', item.commit)
					Snacks.notify("Yanked " .. item.commit)
				end
			end,
			open_diffview = function(picker, item)
				if not item or not item.commit then
					return
				end
				picker:close()
				local ok, _ = pcall(require, "diffview")
				if not ok then
					vim.notify("gitlineage-snack_picker: diffview.nvim is required for this action", vim.log.levels.WARN)
					return
				end
				vim.fn.systemlist({ "git", "rev-parse", "--verify", item.commit .. "^" })
				if vim.v.shell_error ~= 0 then
					vim.cmd("DiffviewOpen " .. item.commit)
				else
					vim.cmd("DiffviewOpen " .. item.commit .. "^!")
				end
			end,
		},
		win = {
			input = {
				keys = {
					["<c-y>"] = { "yank_commit", mode = { "n", "i" }, desc = "Yank commit SHA" },
					["<c-d>"] = { "open_diffview", mode = { "n", "i" }, desc = "Open in Diffview" },
				},
			},
		},
	})
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	local keymap = M.config.keymap
	if keymap then
		vim.keymap.set("n", keymap, function()
			M.pick()
		end, { desc = "Git line history (picker)" })

		vim.keymap.set("v", keymap, ":<C-u>lua require('gitlineage_snack_picker').pick()<CR>", {
			silent = true,
			desc = "Git line history (picker)",
		})
	end

	vim.api.nvim_create_user_command("GitLineageSnackPicker", function(cmd)
		M.pick({ line1 = cmd.line1, line2 = cmd.line2 })
	end, { range = true, desc = "Show git line history in picker" })
end

return M
