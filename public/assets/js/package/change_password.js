function isFloatNegativeKey(e,vls){

	  if (e.charCode >= 32 && e.charCode < 127 && !/^-?\d*[.,]?\d*$/.test(vls + '' + String.fromCharCode(e.charCode)))
	  {
		return false;
	  }
	  return true;
}

function isNumberFloatKey(evt)
 {
	  var charCode = (evt.which) ? evt.which : evt.keyCode;
	  if (charCode != 46 && charCode > 31 && (charCode < 48 || charCode > 57)){
		  return false;
	  }
	  return true;
   }

function isNumberKeys(evt) {
    evt = (evt) ? evt : window.event;
    var charCode = (evt.which) ? evt.which : evt.keyCode;
    if (charCode > 31 && (charCode < 48 || charCode > 57)) {
        return false;
    }
    return true;
}

function change_password_validation(){
    var user_password = $.trim( $("#user_password").val() );
    var new_password  = $.trim( $("#new_password").val() );
    if( user_password != new_password ){
        alert("Confirm password mismatched");
        return false;
    }
}

function alertChecked(url){
    if( confirm("Are you sure want to delete ?")){
        window.location = url
    }
}

function togglePasswordField() {
    const passwordField = document.getElementById('old_password');
    const toggleIcon = document.getElementById('togglePassword');
  
    if (passwordField.type === 'password') {
        passwordField.type = 'text';
        toggleIcon.classList.remove('fa-eye');
        toggleIcon.classList.add('fa-eye-slash');
    } else {
        passwordField.type = 'password';
        toggleIcon.classList.remove('fa-eye-slash');
        toggleIcon.classList.add('fa-eye');
    }
  }
  
  function togglePasswordnewField() {
    const passwordField = document.getElementById('user_password');
    const toggleIcon = document.getElementById('togglePasswordnew');
  
    if (passwordField.type === 'password') {
        passwordField.type = 'text';
        toggleIcon.classList.remove('fa-eye');
        toggleIcon.classList.add('fa-eye-slash');
    } else {
        passwordField.type = 'password';
        toggleIcon.classList.remove('fa-eye-slash');
        toggleIcon.classList.add('fa-eye');
    }
  }
  function togglePasswordconfirmField() {
    const passwordField = document.getElementById('new_password');
    const toggleIcon = document.getElementById('togglePasswordconfirm');
  
    if (passwordField.type === 'password') {
        passwordField.type = 'text';
        toggleIcon.classList.remove('fa-eye');
        toggleIcon.classList.add('fa-eye-slash');
    } else {
        passwordField.type = 'password';
        toggleIcon.classList.remove('fa-eye-slash');
        toggleIcon.classList.add('fa-eye');
    }
  }

  
   // Function to handle showing/hiding password fields based on selected option
   function showHidePasswordFields() {
    const userPasswordField = document.getElementById('user_password');
    const newPasswordField = document.getElementById('new_password');

    const generatedPassword = generatePassword(); // Assuming you have a function named generatePassword()

    // Update user password field
    userPasswordField.value = generatedPassword;
    userPasswordField.type = 'password';
    userPasswordField.readOnly = false;

    // Update new password field
    newPasswordField.value = generatedPassword;
    newPasswordField.type = 'password';
    newPasswordField.readOnly = false;
}


  
  // Function to generate a random password (You can use your implementation here)
  function generatePassword() {
    const length = 10; // Define the length of the generated password
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+{}[]|:;"<>,.?/~'; // Define the characters used in the password
    let password = '';
  
    for (let i = 0; i < length; i++) {
      const randomIndex = Math.floor(Math.random() * charset.length);
      password += charset[randomIndex];
    }
  
    return password;
  }

  
async function copyPasswordToClipboard() {
    const newPasswordField = document.getElementById('user_password');
  
    // Check if the new_password field has a value
    if (!newPasswordField.value) {
      alert('Password field is empty. Please enter a password.');
      return; // Exit the function if the password field is empty
    }
  
    try {
      await navigator.clipboard.writeText(newPasswordField.value);
      alert('Text copied to clipboard');
    } catch (err) {
      alert('Unable to copy text to clipboard. Error: ' + err);
    }
  }