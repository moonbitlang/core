from zhipuai_model import ChatZhipuAI
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate


def get_line_content(moonbit_code, index):
    lines = moonbit_code.strip().split("\n")

    if 0 <= index < len(lines):
        return lines[index]
    else:
        return "Index out of range"


def get_coverage_from_summary(file_path):
    with open(file_path, "r") as file:
        lines = file.readlines()
        last_line = lines[-1].strip()

        parts = last_line.split(":")
        if len(parts) == 2 and parts[0].strip() == "Total":
            total_parts = parts[1].strip().split("/")
            if len(total_parts) == 2:
                total_passed = int(total_parts[0])
                total_tests = int(total_parts[1])
                coverage = total_passed / total_tests
                return coverage
    return 0.0


def read_coverage(moonbit, index, api_key):
    uncovered_code = get_line_content(moonbit, index)
    read_prompt = ChatPromptTemplate.from_template(
        """
        The following piece of code from a larger moonbit language codebase (moonbit_code):{moonbit_code}

         You are provided with one line of code which is uncovered in the test(uncovered_code):{uncovered_code}

         Your task is to identify the entire function that this line of code belongs to and return the complete function definition.

          Please ensure that you include all lines of the function from its definition to the end of the function body.

          Your output should follow this format:

          **Output Format:**
            ```moonbit  
               <complete function>
            ```
        """
    )

    read_llm = ChatZhipuAI(api_key=api_key, model="glm-4-plus", temperature=0.5)

    read_retriever_chain = read_prompt | read_llm | StrOutputParser()
    response = read_retriever_chain.invoke(
        {"moonbit_code": moonbit, "uncovered_code": uncovered_code}
    )
    return response
