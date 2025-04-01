/**
 * Common JavaScript functions for the Redmine MCP Extension
 */

/**
 * Format a date string to a more readable format
 * @param {string} dateString - The date string to format
 * @returns {string} Formatted date string
 */
function formatDate(dateString) {
    const options = { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' };
    return new Date(dateString).toLocaleDateString(undefined, options);
}

/**
 * Load a prompt template by ID
 * @param {number} id - The template ID to load
 */
function loadPromptTemplate(id) {
    fetch(`/api/prompts/${id}`)
        .then(response => response.json())
        .then(data => {
            document.getElementById('templateId').value = data.id;
            document.getElementById('templateName').value = data.name;
            document.getElementById('templateDescription').value = data.description || '';
            document.getElementById('templateContent').value = data.template;
            document.getElementById('templateFormModalLabel').textContent = 'Edit Prompt Template';
            
            // Get the Bootstrap modal instance and show it
            const modalElement = document.getElementById('templateFormModal');
            const modal = bootstrap.Modal.getInstance(modalElement) || new bootstrap.Modal(modalElement);
            modal.show();
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error loading template. Please try again.');
        });
}

/**
 * Create a new template by resetting the form and showing the modal
 */
function newTemplate() {
    // Reset form fields
    document.getElementById('templateForm').reset();
    document.getElementById('templateId').value = '';
    document.getElementById('templateFormModalLabel').textContent = 'New Prompt Template';
    
    // Get the Bootstrap modal instance and show it
    const modalElement = document.getElementById('templateFormModal');
    const modal = bootstrap.Modal.getInstance(modalElement) || new bootstrap.Modal(modalElement);
    modal.show();
}

/**
 * Delete a template after confirmation
 * @param {number} id - The template ID to delete
 */
function deleteTemplate(id) {
    if (confirm('Are you sure you want to delete this template? This action cannot be undone.')) {
        fetch(`/api/prompts/${id}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json'
            }
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Reload page to show updated templates
                window.location.reload();
            } else {
                alert('Error deleting template: ' + data.message);
            }
        })
        .catch(error => {
            console.error('Error:', error);
            alert('Error deleting template. Please try again.');
        });
    }
}

/**
 * Toggle the visibility of a password field
 * @param {string} fieldId - The ID of the field to toggle
 */
function toggleFieldVisibility(fieldId) {
    const field = document.getElementById(fieldId);
    if (field.type === 'password') {
        field.type = 'text';
    } else {
        field.type = 'password';
    }
}