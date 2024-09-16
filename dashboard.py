import streamlit_authenticator as stauth, streamlit as st
import yaml
from yaml.loader import SafeLoader

with open('credentials.yaml') as file:
    credentials = yaml.load(file, Loader=SafeLoader)

authenticator = stauth.Authenticate(
    credentials['credentials'],
    credentials['cookie']['name'],
    credentials['cookie']['key'],
    credentials['cookie']['expiry_days'],
    credentials['preauthorized']
)

try:
    authenticator.login()
except LoginError as e:
    st.error(e)

print(st.session_state)
if st.session_state["authentication_status"]:
    authenticator.logout()
    st.write(f'Welcome *{st.session_state["name"]}*')
    st.title('Some content')
elif st.session_state["authentication_status"] is False:
    st.error('Username/password is incorrect')
elif st.session_state["authentication_status"] is None:
    st.warning('Please enter your username and password')
