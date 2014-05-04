// File: app/inc/js/confirm.js
// Desc: confirm dialogues on sensitive forms (ie deletes)

'use strict';

util.each(util.elements('form[data-confirm-message]'), function(key, $form) {
    $form.addEventListener('submit', function(ev) {
        ev.preventDefault();

        var message_class = $form.getData('confirm-message-class') || 'warning',
            button_class = $form.getData('confirm-button-class') || 'red',
            button_text = $form.getData('confirm-button-text') || 'Continue &#187;',
            message = $form.getData('confirm-message');

        messages.confirm(message_class, button_class, button_text, message, function() {
            $form.submit();
        });
    });
});