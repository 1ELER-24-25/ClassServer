// Function to fetch and display a hint
function fetchAndDisplayHint(buttonElement) {
    const hintNumber = buttonElement.dataset.hintNumber;
    const apiUrl = buttonElement.dataset.apiUrl;
    const hintTextDiv = document.getElementById(`hint-text-${hintNumber}`);
    // Use a more specific selector for the error div if needed, e.g., based on parent
    const errorDiv = buttonElement.closest('.hint').nextElementSibling; // Assuming error div is sibling

    // Ensure elements exist
    if (!hintTextDiv || !apiUrl) {
        console.error(`Missing elements for hint ${hintNumber}`);
        return;
    }

    // Show loading state only if triggered by click, not auto-load
    const isLoading = !buttonElement.disabled;
    if (isLoading) {
        buttonElement.textContent = `Hint ${hintNumber} (Laster...)`;
    }
    buttonElement.disabled = true; // Disable button

    // Clear previous errors for this specific hint area if errorDiv exists
    if (errorDiv && errorDiv.classList.contains('text-danger')) {
         errorDiv.style.display = 'none';
         errorDiv.textContent = '';
    }

    fetch(apiUrl, {
        method: 'POST',
        headers: {
            // Add CSRF token header if needed by Flask-WTF/SeaSurf
            // 'X-CSRFToken': '{{ csrf_token() }}' // This needs server-side rendering into JS
        }
    })
    .then(response => {
        if (!response.ok) {
            return response.json().then(err => {
                throw new Error(err.error || `HTTP error! status: ${response.status}`);
            }).catch(() => {
                throw new Error(`HTTP error! status: ${response.status}`);
            });
        }
        return response.json();
    })
    .then(data => {
        // Replace literal '\n' with <br> tags for proper display within <pre> via innerHTML
        const formattedHintText = data.hint_text.replace(/\\n/g, '<br>');
        
        // Use innerHTML to render potential HTML tags in the hint text
        hintTextDiv.innerHTML = formattedHintText; 
        hintTextDiv.style.display = 'block';

        // If Highlight.js is loaded, tell it to re-scan the specific code block
        if (typeof hljs !== 'undefined') {
            const codeBlock = hintTextDiv.querySelector('code');
            if (codeBlock) {
                 hljs.highlightElement(codeBlock);
            }
        }

        // Update button text to show it's used (only if it wasn't already disabled)
        const buttonText = (hintNumber === '4') ? 'Kode Vist' : `Hint ${hintNumber} (Brukt)`;
        buttonElement.textContent = buttonText; // Set final text regardless of initial state

    })
    .catch(error => {
        console.error('Error fetching hint:', error);
        if (errorDiv && errorDiv.classList.contains('text-danger')) {
            errorDiv.textContent = `Feil ved henting av hint: ${error.message}`;
            errorDiv.style.display = 'block';
        }
         // Keep button disabled but indicate error
         const catchButtonText = (hintNumber === '4') ? 'Feil ved henting av kode' : `Hint ${hintNumber} (Feil)`;
         buttonElement.textContent = catchButtonText;
    });
}


document.addEventListener('DOMContentLoaded', function() {
    const hintButtons = document.querySelectorAll('.hint-button');

    hintButtons.forEach(button => {
        // Add click listener
        button.addEventListener('click', function() {
            fetchAndDisplayHint(this); // Call the refactored function
        });

        // Check if hint is already used on page load (button is disabled)
        if (button.disabled) {
            // Fetch and display the hint automatically
            // Add a small delay to ensure the rest of the page is ready (optional)
            setTimeout(() => fetchAndDisplayHint(button), 50);
        }
    });
});
