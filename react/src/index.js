import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import App from './App';
import registerServiceWorker from './registerServiceWorker';
import concepts from './concepts.json'

ReactDOM.render(<App concepts={concepts} />, document.getElementById('root'));
registerServiceWorker();
