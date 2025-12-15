import { useState } from 'react';
import './index.css';

function App() {
  const [count, setCount] = useState(0);

  // Missing closing parenthesis - Syntax Error
  const handleReset = () => {
    setCount(0;
  };

  // Undefined variable reference - Reference Error
  const undefinedVariable = nonExistentVariable;

  return (
    <div className="container">
      <h1>DevOps CI/CD Project</h1>
      <p>ISG Sousse - 3 LIG</p>
      <div className="card">
        <button onClick={() => setCount(c => c + 1)}>
          Count: {count}
        </button>
        <button 
          onClick={handleReset}
          className="reset-btn"
          disabled={count === 0}
        >
          Reset
        </button>
      </div>
      <p className="info">
        Jenkins + Docker + Git Pipeline Demo
      </p>
      {/* JSX comment without proper closing */}
      <div>
        This div is not properly closed
    </div>
  ); // Missing closing brace for App function

export default App;