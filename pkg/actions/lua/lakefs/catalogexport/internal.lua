local DEFAULT_SHORT_DIGEST_LEN=6

local function short_digest(digest, len)
    return digest:sub(1, len or DEFAULT_SHORT_DIGEST_LEN)
end 

-- paginate lakefs api 
local function lakefs_paginiated_api(api_call, after)
    local next_offset = after
    local has_more = true
    return function()
        if not has_more then
            return nil
        end
        local code, resp = api_call(next_offset)
        if code < 200 or code >= 300 then
            error("lakeFS: api return non-2xx" .. tostring(code))
        end
        has_more = resp.pagination.has_more
        next_offset = resp.pagination.next_offset
        return resp.results
    end
end

-- paginage over lakefs objects 
local function lakefs_object_pager(lakefs_client, repo_id, commit_id, after, prefix, delimiter, page_size)
    return lakefs_paginiated_api(function(next_offset)
        return lakefs_client.list_objects(repo_id, commit_id, next_offset, prefix, delimiter, page_size or 30)
    end, after)
end

-- resolve ref value from action global, used as part of setting default table name
local function ref_from_branch_or_tag(action_info)
    local event = action_info.event_type
    if event == "pre-create-tag" or event == "post-create-tag" then
        return action_info.tag_id
    elseif event == "pre-create-branch" or event == "post-create-branch" or "post-commit" or "post-merge" then
        return action_info.branch_id
    else
        error("unsupported event type: " .. action_info.event_type)
    end
end

return {
    short_digest=short_digest,
    ref_from_branch_or_tag=ref_from_branch_or_tag,
    lakefs_object_pager=lakefs_object_pager, 
    lakefs_paginiated_api=lakefs_paginiated_api,
}