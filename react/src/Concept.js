import React, { Component } from 'react';

class Concept extends Component {

  longClass(title) {
    if (title.length > 12) {
      return 'long';
    }
  }

  render() {
    const {concept} = this.props

    return (
      <li className='concept'>
        <div className="image">
          <img src={`http://hrcpt.online/${concept.screenshot_url}`} alt='concept screenshot' />
        </div>
        <div className="concept-heading">
          <div className={ `title ${this.longClass(concept.title)}` }>
            <a href="hrcpt_url">
              <span>{concept.title}</span>
            </a>
          </div>
          <div className="author">
            <a href={concept.author_url}>by {concept.author}</a>
          </div>
        </div>
        <div className="description" >
          {concept.description}
        </div>
        <div className="repo">
          <div className='link'>
            <a href={concept.github_url}>
              github
            </a>
          </div>
        </div>
      </li>
    );
  }
}

export default Concept;
