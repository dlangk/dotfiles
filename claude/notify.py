import sys, json, subprocess, os, datetime

data = json.load(sys.stdin)

message  = data.get('message', 'Task complete')
session  = data.get('session_id', 'unknown')[:8]
is_error = data.get('is_error', False)
tool     = data.get('tool_name', '')
cwd      = data.get('cwd', os.getcwd())
project  = os.path.basename(cwd)
ts       = datetime.datetime.now().strftime('%H:%M:%S')

# Determine urgency and emoji from context
if is_error:
    priority = 'urgent'
    tags     = 'rotating_light,x'
    title    = f'Claude ERROR: {project}'
elif any(w in message.lower() for w in ['permission', 'approve', 'allow', 'waiting']):
    priority = 'high'
    tags     = 'raised_hand,hourglass'
    title    = f'Claude needs you: {project}'
elif any(w in message.lower() for w in ['complete', 'finished', 'done', 'success']):
    priority = 'default'
    tags     = 'white_check_mark'
    title    = f'Claude finished: {project}'
else:
    priority = 'low'
    tags     = 'speech_balloon'
    title    = f'Claude update: {project}'

# Rich body
lines = [message]
if tool:
    lines.append(f'\n**Last tool:** `{tool}`')
    lines.append(f'**Dir:** `{cwd}`')

body  = '\n'.join(lines)
topic = os.environ.get('NTFY_TOPIC', 'langkilde-dlmacbook')

subprocess.run([
    'curl', '-s',
    '-d', body,
    '-H', f'Title: {title}',
    '-H', f'Priority: {priority}',
    '-H', f'Tags: {tags}',
    '-H', 'Markdown: yes',
    '-H', f'Click: vscode://file{cwd}',  # tapping notification opens project in VS Code
    f'ntfy.sh/{topic}'
])
