import React, { Component } from 'react';
import FontAwesomeIcon from '@fortawesome/react-fontawesome';
import faGithub from '@fortawesome/fontawesome-free-brands/faGithub';

class Concept extends Component {
  renderLanguages(languages) {
    return languages.map((lang) => {
      return (
        <div className="pill">{lang}</div>
      )
    })
  }

  render() {
    const { concept } = this.props;

    return (
      <li className="concept">
        <div className="image">
          <a href={concept.hrcpt_url}>
            <img
              src={`http://hrcpt.online/${concept.screenshot_url}`}
              alt="concept screenshot"
            />
          </a>
        </div>
        <div className="concept-heading">
          <div className="title">
            <a href={concept.hrcpt_url}>
              <span>{concept.title}</span>
            </a>
          </div>
          <div className="repo">
            <div className="link">
              <a href={concept.github_url}>
                <FontAwesomeIcon icon={faGithub} size="lg" />
              </a>
            </div>
          </div>
        </div>
        <div className="author">
          <a href={concept.author_url}>{concept.full_name}</a>
        </div>
        <div className="description">{concept.description}</div>
        <div className="tech-stack">
          { this.renderLanguages(concept.languages) }
        </div>
      </li>
    );
  }
}

export default Concept;
