import React, { Component } from 'react';
import FontAwesomeIcon from '@fortawesome/react-fontawesome';
import faGithub from '@fortawesome/fontawesome-free-brands/faGithub';

class Concept extends Component {
  render() {
    const { concept } = this.props;

    return (
      <li className="concept">
        <div className="image">
          <img
            src={`http://hrcpt.online/${concept.screenshot_url}`}
            alt="concept screenshot"
          />
        </div>
        <div className="concept-heading">
          <div className="title">
            <a href="hrcpt_url">
              <span>{concept.title}</span>
            </a>
          </div>
          <div className="repo">
            <div className="link">
              <FontAwesomeIcon icon={faGithub} size="lg" />
            </div>
          </div>
        </div>
        <div className="author">
          <a href={concept.author_url}>Chris Erin</a>
        </div>
        <div className="description">{concept.description}</div>
        <div className="tech-stack">
          <div className="pill">rails</div>
          <div className="pill">react</div>
        </div>
      </li>
    );
  }
}

export default Concept;
