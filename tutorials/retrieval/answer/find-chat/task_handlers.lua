
-- CONVERSATION-SCOPE VARIABLES

-- TASK SCRIPTS

function write_log(function_name, message)
  local log = get_log("application")
  log:write_line(log_level_normal(), "[task_handlers.lua] - " .. function_name .. "(): ".. message)
end

function get_text(document, xpath)
  return document:XPathValue(xpath)
end

function updateChatHistory(taskUtils, text)
  local chat_history = taskUtils:getSessionVar("CHAT_HISTORY")

  if #chat_history == 0 then 
    chat_history = text
  else 
    chat_history = chat_history .. "+" .. text
  end

  taskUtils:setSessionVar("CHAT_HISTORY", chat_history)
  return chat_history
end

-- Clear user name and chat history when restart a session.
function clear_name_and_chat(taskUtils)
  taskUtils:clearSessionVar("USER_NAME")
  taskUtils:setSessionVar("CHAT_HISTORY", "")
end

-- Convert user name to Title Case.
function normalize_name(taskUtils)
  local input_name = taskUtils:getSessionVar("USER_NAME")
  local name = input_name:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end)
  taskUtils:setSessionVar("USER_NAME", name)
end

-- Ask the next question.
function ask_answer_server(taskUtils)
  local question = taskUtils:getUserText()
  write_log("ask_answer_server", question)

  -- Update chat history
  local prompt = updateChatHistory(taskUtils, question)
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
    
    local answer = get_text(answers[1], "/answer/text")
    write_log("ask_answer_server", answer)
    
    local score = get_text(answers[1], "/answer/score")
    local prompt_success = LuaUserPrompt:new(string.format("%s\n\nAnswer score: %s", answer, score))
    
    local source_ref = get_text(answers[1],"/answer/metadata/sources[1]/source/@ref")
    local source_title = get_text(answers[1],"/answer/metadata/sources[1]/source/@title")
    local source_database = get_text(answers[1],"/answer/metadata/sources[1]/source/@database")
    local source_text = get_text(answers[1],"/answer/metadata/sources[1]/source/text")
    local source_detail = string.format(
      "%s\n\nReference: %s\nTitle: %s\nDatabase: %s", 
      source_text, source_ref, source_title, source_database
    )

    taskUtils:setSessionVar("LAST_ANSWER_SOURCE", source_detail)
    taskUtils:setPrompts({prompt_success})

    -- Update chat history
    updateChatHistory(taskUtils, answer)
    
  else 
    local prompt_failure = LuaUserPrompt:new(
      string.format("Sorry, I couldn't find any relevant information regarding '%s'.", question)
    )
    taskUtils:clearSessionVar("LAST_ANSWER_SOURCE")
    taskUtils:setPrompts({prompt_failure})

    -- Update chat history
    updateChatHistory(taskUtils, "I couldn't find any relevant information.")
    
  end
end

function handle_answer(taskUtils)
  local requested = taskUtils:getSessionVar("DETAILS_REQUESTED")
  -- write_log("handle_answer", "details requested: " .. requested)

  if requested == "Y" then
    taskUtils:setNextTask("ANSWERED")
  
  elseif requested == "N" then
    taskUtils:setNextTask("NEXT")
  end
  
  taskUtils:clearSessionVar("DETAILS_REQUESTED")
end

function show_answer_source(taskUtils)
  local source_text = taskUtils:getSessionVar("LAST_ANSWER_SOURCE")
  local prompt_success = LuaUserPrompt:new(source_text)
  taskUtils:setPrompts({prompt_success})
  taskUtils:clearSessionVar("LAST_ANSWER_SOURCE")
end
