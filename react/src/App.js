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

    this.state = {currentTag: "", modalDisplay: false}
  }

  handleTagChange = (tag) => {
    this.setState({currentTag: tag})
  }

  renderTechNavs(concepts) {
    const results = this.filterMostUsedTechs(concepts);

    return results.map((result) => {
      return <div className={`menu-item ${this.state.currentTag === result ? 'selected' : ''}` } onClick={ () => { this.handleTagChange(result) } }>{result}</div>
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
    const sortedConcepts = sortBy(concepts, concept => new Date(concept.created_at));

    return reverse(sortedConcepts).map((concept) =>
      <Concept concept={concept} onPillClick={this.handleTagChange}/>
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
        <Modal display={this.state.modalDisplay} closeModal={() => this.setState({modalDisplay: false})} />
        <header className="App-header">
          <div className="header-title">
            <a href='/'>
              <Lettering />
            </a>
            <div className="hr-container">
              <h2>
                <a href="https://hashrocket.com" class="hr">A Hashrocket project</a>
                <div className="tag-line" onClick={() => this.setState({modalDisplay: true})}>A Gallery of Side Projects</div>
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

const Modal = (props) => {
  return (
    <div className="modal" onClick={props.closeModal} style={{display: props.display ? "block" : "none"}}>
      <div className="modal-content">
        <h2>About</h2>
        <p>
        Concepts is a place for us to put our side projects on display. When learning a new technology we've found it's best to try and make something. These projects very often look like rough, incomplete ideas, but they represent a new frontier for a Hashrocketeer in our learning about programming.
        </p>
      </div>
    </div>
  );
}

export default App;
