window.addEventListener('message', function(event) {
    let data = event.data;
    if (data.type === 'OPEN_INTERACTION_MENU') {
        openMenu(data.options);
    } else if (data.type === 'OPEN_NAMING_BOX') {
        document.getElementById('dialogue-box').classList.add('hidden');
        document.getElementById('interaction-menu').classList.add('hidden');
        document.getElementById('naming-box').classList.remove('hidden');
        document.getElementById('companion-name-input').value = '';
        document.getElementById('companion-name-input').focus();
    } else if (data.type === 'SHOW_TYPING') {
        document.getElementById('dialogue-box').classList.remove('hidden');
        document.getElementById('dialogue-text').innerText = 'GENERATING NATIVE AI RESPONSE...';
        document.getElementById('interaction-menu').classList.add('hidden');
    } else if (data.type === 'UPDATE_DIALOGUE') {
        document.getElementById('dialogue-box').classList.remove('hidden');
        document.getElementById('dialogue-text').innerText = data.text;
        setTimeout(() => {
            document.getElementById('dialogue-box').classList.add('hidden');
            fetch(`https://${GetParentResourceName()}/closeMenu`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }, 6000);
    }
});

function openMenu(options) {
    const menu = document.getElementById('interaction-menu');
    const container = document.getElementById('options-container');
    container.innerHTML = '';
    
    options.forEach(opt => {
        const btn = document.createElement('button');
        btn.className = 'option-btn';
        btn.innerText = opt.label;
        btn.onclick = () => selectOption(opt.action);
        container.appendChild(btn);
    });
    
    menu.classList.remove('hidden');
}

function closeMenu() {
    document.getElementById('interaction-menu').classList.add('hidden');
    document.getElementById('naming-box').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

document.getElementById('confirm-name-btn').addEventListener('click', function() {
    let name = document.getElementById('companion-name-input').value.trim();
    if (name.length > 0) {
        document.getElementById('naming-box').classList.add('hidden');
        fetch(`https://${GetParentResourceName()}/recruitCompanionWithName`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: name })
        });
    }
});

function selectOption(action) {
    document.getElementById('interaction-menu').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/selectOption`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: action })
    });
}

window.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeMenu();
    }
});
