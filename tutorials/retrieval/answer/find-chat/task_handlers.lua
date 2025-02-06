
-- CONVERSATION-SCOPE VARIABLES

MAX_CHAT_CONTEXT = 6 -- three question-answer pairs
MAX_LISTED_SOURCES = 3 -- to display under answers

-- TASK SCRIPTS

function write_log(function_name, message)
  local log = get_log("application")
  log:write_line(log_level_normal(), "[task_handlers.lua] - " .. function_name .. "(): ".. message)
end

function update_chat_history(taskUtils, text)
  local chat_history = taskUtils:getSessionVar("CHAT_HISTORY")

  if #chat_history == 0 then 
    chat_history = text
  else 
    chat_history = chat_history .. "+" .. text
  end

  taskUtils:setSessionVar("CHAT_HISTORY", chat_history)
  return chat_history
end

function split_line_char(line, char)
  local result = {}
  for value in string.gmatch(line, '([^'..char..']+)') do
      table.insert(result, value)
  end
  return result
end

function expire_chat_history(taskUtils)
  
  local chat_history = taskUtils:getSessionVar("CHAT_HISTORY")
  if #chat_history == 0 then return end
  
  local chat_list = split_line_char(chat_history, "+")
  if #chat_list <= MAX_CHAT_CONTEXT then return end
  
  -- write_log("expire_chat_history", "was: " .. #chat_list)
  local start = #chat_list - MAX_CHAT_CONTEXT
  local new_chat_list = {}
  for i, v in ipairs(chat_list) do
    if i > start then 
      table.insert(new_chat_list, v)
    end
  end

  -- write_log("expire_chat_history", "new: " .. #new_chat_list)
  taskUtils:setSessionVar("CHAT_HISTORY", table.concat(new_chat_list, '+'))
end

-- Clear chat history when restarting a session.
function initialize_session(taskUtils)
  taskUtils:setSessionVar("CHAT_HISTORY", "")
  write_log("initialize_session", "Reset chat history.")
end

-- Replicate Find's "Open Original" link.
function open_original_link(ref, db_name, answer)
  return "<a href=\"/api/public/view/viewDocument" ..
    "?reference=" .. ref .. 
    "&part=DOCUMENT" ..
    "&index=" .. db_name ..
    "&highlightExpressions=" .. answer ..
    "\" target=\"_blank\">".. ref .. "</a>"
end

-- Ask a question.
function ask_answer_server(taskUtils)
  local question = taskUtils:getUserText()
  write_log("ask_answer_server", "user: " .. question)

  -- Update chat history
  expire_chat_history(taskUtils)
  local prompt = update_chat_history(taskUtils, question)
  write_log("ask_answer_server", prompt)

  -- Run the ask action
  local answer_systems = {"RAG"}
  local answers = taskUtils:ask(prompt, answer_systems, 1, false)

  -- Handle the results
  if #answers > 0 then
    --[[
    <answer answer_type="rag" system_name="RAG">
      <text>Management's responsibility is to its employees, customers, and the community at large.</text>
      <score>84.78</score>
      <interpretation>what is management's responsibility?</interpretation>
      <source>dede952d-8a4d-4f54-ac1f-5187bf10a744</source>
      <metadata>
        <sources>
          <source ref="dede952d-8a4d-4f54-ac1f-5187bf10a744" title="Thought for the day" database="Demo">
            <text>Thought for the day. "Somehow, we got into a discussion of the responsibility of management. [The moderator] made the point that management’s responsibility is to the shareholders - that’s the end of it. And I objected. I said, ‘I think you’re absolutely wrong. Management has a responsibility to its employees, it has a responsibility to its customers, it has a responsibility to the community at large.’ And they almost laughed me out of the room. I think many people assume, wrongly, that a company exists simply to make money. While this is an important result of a company’s existence, we have to go deeper to find our real reason for being…A group of people get together and exist as an institution that we call a company…to do something worthwhile – they make a contribution to society." - Dave Packard </text>
          </source>
        </sources>
      </metadata>
    </answer>
    ]]--
    
    local answer = answers[1]:XPathValue("/answer/text")
    write_log("ask_answer_server", "assistant: " .. answer)
    
    local prompt_message = answer .. "\n\nReferences:" 
    
    local source_ref_list = { answers[1]:XPathValues("/answer/metadata/sources/source/@ref") }
    local source_db_list = { answers[1]:XPathValues("/answer/metadata/sources/source/@database") }
    for i, v in ipairs(source_ref_list) do
      write_log("ask_answer_server", "sources: " .. v .. " " .. source_db_list[i])
      if i > MAX_LISTED_SOURCES then break end
      prompt_message = prompt_message .. "\n  - " .. open_original_link(v, source_db_list[i], answer)
    end

    local prompt_success = LuaUserPrompt:new(prompt_message)
    
    taskUtils:setPrompts({prompt_success})

    -- Update chat history
    update_chat_history(taskUtils, answer)
    
  else 
    local prompt_failure = LuaUserPrompt:new(string.format(
      "Sorry, I couldn't find any relevant information regarding '%s'.", question
    ))
    taskUtils:setPrompts({prompt_failure})

    -- Update chat history
    update_chat_history(taskUtils, "")
    
  end
end
