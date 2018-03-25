import React, { Component } from 'react';
import Lettering from './Lettering'
import Concept from './Concept';
import './App.css';
import sortBy from 'lodash/sortBy';
import reverse from 'lodash/reverse';
import take from 'lodash/take';

class App extends Component {
  constructor() {
    super()

    this.state = {currentTag: ""}
  }

  handleTagChange = (tag) => {
    this.setState({currentTag: tag})
  }

  renderTechNavs(concepts) {
    const results = this.filterMostUsedTechs(concepts);

    return results.map((result) => {
      return <div className="menu-item" onClick={ () => { this.handleTagChange(result) } }>{result}</div>
    });
  }

  filterMostUsedTechs(concepts) {
    const results = {};

    concepts.forEach((concept) => {
      concept.languages.forEach((language) => {
        if (results[language]) {
          results[language]++;
        } else {
          results[language] = 1;
        }
      })
    })

    const languages = Object.entries(results);
    const sortedLanguages = sortBy(languages, (languageCount) => { return languageCount[1]});

    return take(reverse(sortedLanguages.map((t) => t[0])), 7);
  }

  renderConcepts(concepts) {
    return concepts.map((concept) =>
      <Concept concept={concept}/>
    )
  }

  filterConceptsByTag(concepts) {
    return concepts.filter((concept) => {
      return concept.languages.find((lang) => {
        return lang.match(this.state.currentTag)
      })
    })
  }

  render() {
    return (
      <div className="App">
        <header className="App-header">
          <div className="header-title">
            <a href='/'>
              <Lettering />
            </a>
            <div className="hr-container">
              <h2>
                <a href="https://hashrocket.com" class="hr">A Hashrocket project</a>
              </h2>
            </div>
          </div>
        </header>
        <nav className="nav">
          {this.renderTechNavs(this.props.concepts)}
        </nav>
        <ul className="concepts">
          {this.renderConcepts(this.filterConceptsByTag(this.props.concepts))}
        </ul>
        <footer className="footer">
        </footer>
      </div>
    );
  }
}

export default App;
