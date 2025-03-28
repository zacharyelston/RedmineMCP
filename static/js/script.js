// Utility functions for the MCP Redmine extension

// Function to format timestamps
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString();
}

// Function to fetch and display a prompt template
function loadPromptTemplate(id) {
    fetch(`/api/prompt_template/${id}`)
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(template => {
            document.getElementById('template-id').value = template.id;
            document.getElementById('template-name').value = template.name;
            document.getElementById('template-description').value = template.description;
            document.getElementById('template-content').value = template.template;
            
            // Show the edit form and scroll to it
            const formElement = document.getElementById('template-form');
            formElement.classList.remove('d-none');
            formElement.scrollIntoView({ behavior: 'smooth' });
        })
        .catch(error => {
            console.error('Error fetching template:', error);
            alert('Error loading template. Please try again.');
        });
}

// Function to create a new template form
function newTemplate() {
    // Clear the form
    document.getElementById('template-form').reset();
    document.getElementById('template-id').value = '';
    
    // Show the form and scroll to it
    const formElement = document.getElementById('template-form');
    formElement.classList.remove('d-none');
    formElement.scrollIntoView({ behavior: 'smooth' });
}

// Function to delete a prompt template
function deleteTemplate(id) {
    if (confirm('Are you sure you want to delete this template?')) {
        fetch(`/api/prompt_template/${id}`, {
            method: 'DELETE'
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            if (data.success) {
                // Remove the template from the DOM
                const templateCard = document.getElementById(`template-card-${id}`);
                if (templateCard) {
                    templateCard.remove();
                }
                
                // Hide the form if we were editing this template
                if (document.getElementById('template-id').value == id) {
                    document.getElementById('template-form').classList.add('d-none');
                }
            }
        })
        .catch(error => {
            console.error('Error deleting template:', error);
            alert('Error deleting template. Please try again.');
        });
    }
}

// Toggle password/API key visibility
function toggleFieldVisibility(fieldId) {
    const field = document.getElementById(fieldId);
    if (field.type === 'password') {
        field.type = 'text';
    } else {
        field.type = 'password';
    }
}

// Add event listeners when the DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    // Format all dates
    document.querySelectorAll('.format-date').forEach(element => {
        element.textContent = formatDate(element.textContent);
    });
    
    // Add form validation
    const forms = document.querySelectorAll('.needs-validation');
    Array.from(forms).forEach(form => {
        form.addEventListener('submit', event => {
            if (!form.checkValidity()) {
                event.preventDefault();
                event.stopPropagation();
            }
            form.classList.add('was-validated');
        }, false);
    });
});
