import React, { Component } from 'react';
import Lettering from './Lettering'
import Concept from './Concept';
import './App.css';

class App extends Component {
  renderConcepts(concepts) {
    return concepts.map((concept) =>
      <Concept concept={concept}/>
    )
  }

  render() {
    return (
      <div className="App">
        <header className="App-header">
          <Lettering />
          <div className="hr-container">
            <h2>
              <a href="https://hashrocket.com" class="hr">A Hashrocket project</a>
            </h2>
          </div>
        </header>
        <nav className="nav">
          <div className="menu-item">Ruby</div>
          <div className="menu-item">ReasonML</div>
          <div className="menu-item">React</div>
          <div className="menu-item">Elm</div>
          <div className="menu-item">Elixir</div>
          <div className="menu-item">Postgres</div>
          <div className="menu-item">React Native</div>
          <div className="menu-item">Golang</div>
        </nav>
        <ul className="concepts">
          {this.renderConcepts(this.props.concepts)}
        </ul>
        <footer className="footer">
        </footer>
      </div>
    );
  }
}

export default App;
