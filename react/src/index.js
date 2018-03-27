import React from 'react';
import ReactDOM from 'react-dom';
import './index.css';
import App from './App';
import conceptsFromFile from './concepts.json'

if (process.env.NODE_ENV === 'production') {
  fetch('/concepts.json').then(function(response) {
    return response.status === 200 ?
      response.json() : Promise.reject({error: response.status})
  }).then(function(concepts) {
    ReactDOM.render(<App concepts={concepts.data} />, document.getElementById('root'));
  })
} else {
  let concepts = conceptsFromFile;
  ReactDOM.render(<App concepts={concepts} />, document.getElementById('root'));
}
