import streamlit as st
import yaml
from yaml.loader import SafeLoader

# Load credentials
with open('credentials.yaml') as file:
    credentials = yaml.load(file, Loader=SafeLoader)

st.title('Amazing User Login App')

# Initialize session state for user
if 'user_state' not in st.session_state:
    st.session_state.user_state = {
        'full_name': '',
        'username': '',
        'password': '',
        'logged_in': False,
        'user_type': '',
        'email_address': ''
    }

# Check if user is already logged in
if not st.session_state.user_state['logged_in']:
    st.write('Please login')
    username = st.text_input('Username')
    password = st.text_input('Password', type='password')
    submit = st.button('Login')

    if submit:
        # Check credentials
        user_info = next((user for user in credentials['credentials']['usernames'] if user['username'] == username), None)
        
        if not user_info:
            st.error('User not found')
        elif user_info['password'] == password:
            st.session_state.user_state.update({
                'username': username,
                'logged_in': True,
                'user_type': user_info['user_type']
            })
            st.success('Successfully logged in!')
            st.experimental_rerun()  # Refresh the page after successful login
        else:
            st.error('Invalid username or password')

# Once logged in, replace the login screen with the new content
if st.session_state.user_state['logged_in']:
    st.title(f"Welcome {st.session_state.user_state['username']}")
    st.write(f"You are logged in as: {st.session_state.user_state['user_type']}")
    
    if st.button("Logout"):
        st.session_state.user_state['logged_in'] = False
        st.experimental_rerun()  # Refresh the page after logging out
