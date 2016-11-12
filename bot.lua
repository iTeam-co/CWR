package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'
URL = require('socket.url')
HTTP = require('socket.http')
JSON = require('dkjson')
redis = (loadfile "./redis.lua")()
HTTPS = require('ssl.https')
----config----
local bot_api_key = "BOT-TOKEN" --token
local BASE_URL = "https://api.telegram.org/bot"..bot_api_key
-------

----utilites----
function is_admin(msg)-- Check if user is admin or not
  local var = false
  local admins = {122774063} --admins id
  for k,v in pairs(admins) do
    if msg.from.id == v then
      var = true
    end
  end
  return var
end

function sendRequest(url)
  local dat, res = HTTPS.request(url)
  local tab = JSON.decode(dat)

  if res ~= 200 then
    return false, res
  end

  if not tab.ok then
    return false, tab.description
  end

  return tab

end

function getMe()--https://core.telegram.org/bots/api#getfile
    local url = BASE_URL .. '/getMe'
  return sendRequest(url)
end

function getUpdates(offset)--https://core.telegram.org/bots/api#getupdates

  local url = BASE_URL .. '/getUpdates?timeout=20'

  if offset then

    url = url .. '&offset=' .. offset

  end

  return sendRequest(url)

end

function sendMessage(chat_id, text, disable_web_page_preview, reply_to_message_id, use_markdown)--https://core.telegram.org/bots/api#sendmessage

	local url = BASE_URL .. '/sendMessage?chat_id=' .. chat_id .. '&text=' .. URL.escape(text)

	if disable_web_page_preview == true then
		url = url .. '&disable_web_page_preview=true'
	end

	if reply_to_message_id then
		url = url .. '&reply_to_message_id=' .. reply_to_message_id
	end

	if use_markdown then
		url = url .. '&parse_mode=Markdown'
	end

	return sendRequest(url)
end

function download_to_file(url, file_name, file_path)--https://github.com/yagop/telegram-bot/blob/master/bot/utils.lua
  print("url to download: "..url)

  local respbody = {}
  local options = {
    url = url,
    sink = ltn12.sink.table(respbody),
    redirect = true
  }
  -- nil, code, headers, status
  local response = nil
    options.redirect = false
    response = {HTTPS.request(options)}
  local code = response[2]
  local headers = response[3]
  local status = response[4]
  if code ~= 200 then return nil end
  local file_path = BASE_FOLDER..currect_folder..file_name

  print("Saved to: "..file_path)

  file = io.open(file_path, "w+")
  file:write(table.concat(respbody))
  file:close()
  return file_path
end
--------

function bot_run()
	bot = nil

	while not bot do -- Get bot info
		bot = getMe()
	end

	bot = bot.result

	local bot_info = "\27[36mCWR Is Running!\27[39m\nCWR's Username : @"..bot.username.."\nCWR's Name : "..bot.first_name.."\nCWR's ID : "..bot.id.." \n\27[36mBot Developed by iTeam\27[39m\n---------------"

	print(bot_info)

	last_update = last_update or 0

	is_running = true

	botusername = bot.username
	
	botid = bot.id
end

function get_response(text)
	local url = 'http://chatter.iteam-co.ir/fa.php?text='..URL.escape(text)
	local json = HTTP.request(url)
	local jdat = JSON.decode(json)
	if jdat.response then
		local msg = jdat.response
		return msg
	else
		return nil
	end
end

function get_answer(msg)
local text = get_response(msg.text)
if text ~= nil then
	return text
else
	return "من اینو بلد نیستم 😋. اما اگه میخوای اینو  /teachme  کلیک کن تا بتونی یادم بدی"
end
end

function msg_processor(msg)
local print_text = "\27[36mChat : "..msg.chat.id..", User : "..msg.from.id.."\27[39m\nText : "..(msg.text or "").."\n---------------"
print(print_text)
if msg.date < os.time() - 5 then -- Ignore old msgs
	print("\27[36m(Old Message)\27[39m\n---------------")
	return
end
if msg.text == '/start' or msg.text == '/start@'..botusername or msg.text == '/start@'..botusername..' new' then
	local text = [[
`سلام من چَتِر بوت 😇  هستم.`

_من هوش مصنوعی دارم 😅 و هرچی‌ تو بگی‌ رو میفهمم و جواب میدم_

*من حدود ۲۰ میلیون کلمه فارسی 🙈 بلدم و میتونم باهاشون باهات حرف بزنم*

اگه میخوای میتونی‌ باهام حرف 😋 بزنی‌!
من تو خصوصی به همه پیامات جواب میدم ولی تو گروها باید روی پیام هایی که من ارسال میکنم ریپلای کنی تا جوابتو بدم :)

راستی اگه منو تو گروهات اضافه کنی خودم ازتون حرف زدن یاد میگیرم]]
    text = text.."\n[برای اضافه کردن من تو گروه خودت با دوستات روی این متن آبی کلیک کن و گروه مورد نظرتو انتخاب کن](https://telegram.me/"..botusername.."?startgroup=new)\nقدرت گرفته از [iTeam](https://telegram.me/iTeam_ir)"
	sendMessage(msg.chat.id, text, false, msg.message_id, true)
	if msg.chat.type == "private" then
		redis:sadd("CW:users",msg.chat.id)
	else
		redis:sadd("CW:chats",msg.chat.id)
	end
elseif msg.text and msg.text:match("(.*)##(.*)") and not msg.caption and not msg.forward_from then
	local matches = {msg.text:match("(.*)##(.*)")}
	if matches[2]:match("(telegram.%s)") or matches[2]:match("@") or matches[2]:match("tlgrm.me") or matches[2]:match("https?://([%w-_%.%?%.:/%+=&]+)") then
		local text = "اضافه کردن لینک و آیدی به عنوان جواب کار دستی نیست دوسته گل\nاین ربات قرار نیست برا شما تبلیغ کنه 😉"
		sendMessage(msg.chat.id, text, false, msg.message_id, true)
	elseif matches[1]:match("(/%s)") then
		local text = "قرار نیست شما بتونی برای من دستور بسازی دوسته گل 😉"
		sendMessage(msg.chat.id, text, false, msg.message_id, true)
	elseif matches[2] == nil then
		local text = "لطفا یه متن برای جواب وارد کنید"
		sendMessage(msg.chat.id, text, false, msg.message_id, true)
	else
			HTTP.request("http://chatter.iteam-co.ir/fa-learn.php?text="..URL.escape(matches[1]).."&answer="..URL.escape(matches[2]))
			local text = "خیلی ممنون که بهم کلمه جدید یاد دادی 😇😍 \n\n حالا بلد شدم اگه بگی 😁  \n"..matches[1].."\n 😋 من جواب بدم \n"..matches[2]
			sendMessage(msg.chat.id, text, false, msg.message_id, true)
		end
elseif msg.text == "/teachme" or msg.text == "/teachme@"..botusername then
	local text = [[اگه بخوای کلمه یا جمله جدید یادم بدی
 😇 باید دو قسمت مسیج یعنی اون چیزی که تو میخوای بفرستی و اون چیزی که میخوای من جواب بدم رو پشت سر هم تو یک مسیج واسم بفرستی و با دو ! پشت سر هم از هم جداشون کنی 
  

مثل این 😊 
 
سلام،خوبی؟##مرسی،ممنونم
  
یا 😋 
  
چه خبر؟##هیچی، تو چه خبر؟
  
یا 😁 
  
Miay berim biroon?##Are, key berim? 
  
ممنون از اینکه بهم چیزای جدید یاد میدی]]
	sendMessage(msg.chat.id, text, false, msg.message_id, true)
elseif msg.text == "/stats" and is_admin(msg) then
	local text = "*Users* : `"..redis:scard("CW:users").."`\n*Chats* : `"..redis:scard("CW:chats").."`"
	sendMessage(msg.chat.id, text, false, msg.message_id, true)
else
	if msg.chat.type == "private" or msg.reply_to_message and msg.reply_to_message.from.id == botid then
		local text = get_answer(msg)
		sendMessage(msg.chat.id, text, false, msg.message_id, true)
	else
		if msg.reply_to_message and msg.reply_to_message.text then
			HTTP.request("http://chatter.iteam-co.ir/fa-learn.php?text="..URL.escape(msg.reply_to_message.text).."&answer="..URL.escape(msg.text))
		end
	end
end
end

function sticker_handler(msg)
	msg.text = msg.sticker.emoji
	return msg_processor(msg)
end

function reply_sticker_handler(msg)
	msg.reply_to_message.text = msg.reply_to_message.sticker.emoji
	return msg_processor(msg)
end

function caption_handler(msg)
	msg.text = msg.caption
	return msg_processor(msg)
end

function reply_caption_handler(msg)
	msg.reply_to_message.text = msg.reply_to_message.caption
	return msg_processor(msg)
end

bot_run() -- Run main function
while is_running do -- Start a loop witch receive messages.
	local response = getUpdates(last_update+1) -- Get the latest updates using getUpdates method
	if response then
		for i,v in ipairs(response.result) do
			last_update = v.update_id
			if v.message then
				if v.message.sticker and v.message.sticker.emoji then
					sticker_handler(v.message)
				elseif v.message.reply_to_message and v.message.reply_to_message.sticker and v.message.reply_to_message.sticker.emoji then
					reply_sticker_handler(v.message)
				elseif v.message.caption then
					caption_handler(v.message)
				elseif v.message.reply_to_message and v.message.reply_to_message.caption then
					reply_caption_handler(v.message)
				else
					msg_processor(v.message)
				end
			end
		end
	else
		print("Conection failed")
	end

end
print("Bot halted")
