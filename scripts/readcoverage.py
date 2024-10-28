from zhipuai import ChatZhipuAI
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate


def get_coverage_from_summary(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
        last_line = lines[-1].strip()

        parts = last_line.split(':')
        if len(parts) == 2 and parts[0].strip() == 'Total':
            total_parts = parts[1].strip().split('/')
            if len(total_parts) == 2:
                total_passed = int(total_parts[0])
                total_tests = int(total_parts[1])
                coverage = total_passed / total_tests
                return coverage
    return 0.0


def read_coverage(moonbit_code, index, api_key):
    read_prompt = ChatPromptTemplate.from_template(
        """You are a professional MoonBit code analyst. Your task is to find and return the complete function definition containing the given uncovered code line indices.

Input:

moonbit: The entire code in which you need to search for uncovered lines.
Uncovered code line index: An integer representing the line number of the code that is marked as uncovered.
Output requirements:

For the given uncovered code line index, locate and return the complete function definition that contains that line.
The output should be a string representing the entire code of a function, including its signature and body.
Do not include any analysis process, additional information, or explanatory statements; just return the required function definition.

Example:
If the uncovered code line index is [2], then the output should be the complete function definition that includes line 2.
 Now, please find the uncovered code based on the following input information:
        moonbit:{moonbit}
        Uncovered code line index:{index}   
Attention, the language of the code is MoonBit.
        
        """
    )

    read_llm = ChatZhipuAI(api_key=api_key, model="glm-4-plus", temperature=0.5)

    read_retriever_chain = read_prompt | read_llm | StrOutputParser()
    response = read_retriever_chain.invoke(
        {"moonbit": moonbit, "index": [index]}
    )
    return response  
        """
    )

    read_llm = ChatZhipuAI(api_key=api_key, model="glm-4-plus", temperature=0.5)

    read_retriever_chain = read_prompt | read_llm | StrOutputParser()
    response = read_retriever_chain.invoke(
        {"moonbit_code": moonbit_code, "index": [index]}
    )
    return response
