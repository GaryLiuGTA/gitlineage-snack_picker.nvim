local M = {}

--- Map working-tree line numbers to HEAD line numbers.
--- Accounts for uncommitted additions/deletions that shift line numbers.
--- @param git_root string
--- @param rel_file string
--- @param l1 integer start line in working tree
--- @param l2 integer end line in working tree
--- @return { l1?: integer, l2?: integer, new_lines: integer[], all_new?: boolean }
function M.map_lines_to_head(git_root, rel_file, l1, l2)
	local diff = vim.fn.systemlist({ "git", "-C", git_root, "diff", "HEAD", "--", rel_file })
	if vim.v.shell_error ~= 0 or #diff == 0 then
		return { l1 = l1, l2 = l2, new_lines = {} }
	end

	local hunks = {}
	local h = nil
	for _, line in ipairs(diff) do
		local os, oc, ns, nc = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
		if os then
			if h then
				table.insert(hunks, h)
			end
			h = {
				old_start = tonumber(os),
				old_count = (oc == "" or oc == nil) and 1 or tonumber(oc),
				new_start = tonumber(ns),
				new_count = (nc == "" or nc == nil) and 1 or tonumber(nc),
				lines = {},
			}
		elseif h then
			local c = line:sub(1, 1)
			if c == " " or c == "+" or c == "-" then
				table.insert(h.lines, line)
			end
		end
	end
	if h then
		table.insert(hunks, h)
	end

	local result_old = {}
	local new_lines = {}
	local old_num = 0
	local new_num = 0

	for _, hunk in ipairs(hunks) do
		local gap_end = hunk.new_start - 1
		while new_num < gap_end do
			new_num = new_num + 1
			old_num = old_num + 1
			if new_num >= l1 and new_num <= l2 then
				table.insert(result_old, old_num)
			end
			if new_num >= l2 then
				break
			end
		end
		if new_num >= l2 then
			break
		end

		for _, dline in ipairs(hunk.lines) do
			local c = dline:sub(1, 1)
			if c == " " then
				new_num = new_num + 1
				old_num = old_num + 1
				if new_num >= l1 and new_num <= l2 then
					table.insert(result_old, old_num)
				end
			elseif c == "+" then
				new_num = new_num + 1
				if new_num >= l1 and new_num <= l2 then
					table.insert(new_lines, new_num)
				end
			elseif c == "-" then
				old_num = old_num + 1
			end
			if new_num >= l2 then
				break
			end
		end
		if new_num >= l2 then
			break
		end
	end

	while new_num < l2 do
		new_num = new_num + 1
		old_num = old_num + 1
		if new_num >= l1 and new_num <= l2 then
			table.insert(result_old, old_num)
		end
	end

	if #result_old == 0 then
		return { new_lines = new_lines, all_new = true }
	end

	return {
		l1 = result_old[1],
		l2 = result_old[#result_old],
		new_lines = new_lines,
	}
end

return M
