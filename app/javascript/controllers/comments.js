document.addEventListener("DOMContentLoaded", function () {
    const replyButtons = document.querySelectorAll('[data-toggle^="reply-form-"]');

    replyButtons.forEach(function (button) {
        button.addEventListener('click', function (event) {
            event.preventDefault();

            const formId = button.getAttribute('data-toggle');
            const form = document.getElementById(formId);

            if (form) {
                form.classList.toggle('hidden');
            }
        });
    });
});
