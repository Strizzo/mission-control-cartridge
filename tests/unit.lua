local m=require('model')
assert(m.url('computer.local')=='http://computer.local:8766')
assert(m.url('https://computer.local')=='https://computer.local:8766')
assert(m.url('::1')=='http://[::1]:8766')
assert(m.url('[::1]:9000')=='http://[::1]:9000')
for _,url in ipairs({'host:0','host:65536','http://user:pass@host','host/path','host?query','host#fragment'}) do
    assert(m.url(url)==nil, 'invalid server URL accepted: '..url)
end
assert(m.clean('ééé',2)=='éé')
assert(m.parse({sessions={broken={}}})==nil)
local sessions={
    ['pane-z']={session_name='work',pane_id='%1',session_type='claude_code',status='running',screen_content={'old','latest','',''},
        response_options={{text='exact "quoted" response',category='approve'},{text=string.rep('x',4097)}},
        detected_choices={{label='yes',key_sequence='1 Enter'}}},
    ['pane-a']={session_name='work',pane_id='%2',session_type='shell',status='waiting',screen_content={'needs input'}},
}
local rows,err,total=m.parse({sessions=sessions})
assert(not err and #rows==2 and total==2)
assert(rows[1].id=='pane-a' and rows[2].id=='pane-z', 'waiting pane must sort first; target is map key')
assert(#rows[2].screen_content==2, 'trailing blank tmux rows must be trimmed')
assert(#rows[2].response_options==1, 'oversized commands must be excluded, not truncated')
assert(rows[2].commands[1].payload.text=='exact "quoted" response')
assert(rows[2].commands[2].payload.keys=='1 Enter')
local ghost=false
for _,c in ipairs(rows[2].commands) do if c.action=='accept_ghost' then ghost=true end end
assert(ghost)
for _,c in ipairs(rows[1].commands) do assert(c.action~='accept_ghost') end
local many={}
for i=1,140 do many['p'..i]={session_name='work',pane_id='%'..i} end
local bounded,_,count=m.parse({sessions=many})
assert(#bounded==128 and count==140)
assert(m.signature({action='send_response',payload={text='a'}}) ~= m.signature({action='send_response',payload={text='b'}}))
print('Mission Control: server validation, stable command targets, bounded data, exact payloads passed')
