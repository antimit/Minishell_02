/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   syntax_error.c                                     :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: yviavant <marvin@42.fr>                    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2021/03/20 03:33:35 by yviavant          #+#    #+#             */
/*   Updated: 2021/03/20 03:33:51 by yviavant         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

/*
 * Skips over a quoted substring (single or double quotes) in `str`
 * starting at index `i`.
 *
 * Behavior:
 *  - If `str[i]` is a quote character (' or "), remember its type and
 *    advance until the matching closing quote is found.
 *  - Backslashes '\' inside the quoted string cause the next character
 *    to be skipped as escaped.
 *  - If the closing quote is missing, scanning stops at the end of the string.
 *
 * Returns:
 *  The index of the character immediately after the closing quote,
 *  or the string length if no closing quote was found.
 *
 * Use case:
 *  Allows the parser to ignore operators (like |, <, >) that appear
 *  inside quoted strings, so they are not mistaken for syntax tokens.
 */


int	inside_quote(char *str, int i)
{
	char	quote;

	while (str[i] && (str[i] == '\'' || str[i] == '"'))
	{
		quote = str[i];
		i++;
		while (str[i] && str[i] != quote)
		{
			if (str[i] && str[i] == '\\')
				i++;
			i++;
		}
		if (i == ((int)ft_strlen(str)))
			break ;
		else
			i++;
	}
	return (i);
}



/*
 * Checks for invalid use of redirection operator `c` ('>' or '<')
 * in the command string `str`.
 *
 * Rules enforced:
 *  - Ignores redirection characters that appear inside quotes.
 *  - Counts consecutive occurrences of `c`.
 *  - More than two consecutive operators (e.g. ">>>", "<<<") is invalid.
 *
 * Parameters:
 *  str : command line string to validate.
 *  c   : redirection operator to check ('>' or '<').
 *
 * Returns:
 *  0 if valid (no redirection syntax error),
 *  non-zero if an error is detected (error_msg() return value).
 *
 * Examples:
 *   "ls > file"    -> OK
 *   "ls >> file"   -> OK
 *   "ls >>> file"  -> Error
 */

 
int	syntax_error_redir(char *str, char c)
{
	int		i;
	int		j;

	i = 0;
	while (str[i])
	{
		j = 0;
		if ((i = (inside_quote(str, i))) == (int)ft_strlen(str))
			break ;
		while (str[i] && (str[i] == c || str[i] == ' '))
		{
			if (str[i] == c)
				j++;
			i++;
			if (j == 3)
				return (error_msg(str, i + 1, c)); // index: 0 1 2 3 4 chars: > > >   f  --- 3 points at space
		}
		if (i == (int)ft_strlen(str))
			break ;
		i++;
	}
	return (0);
}


/*
 * Returns an error if the last non-space character of `str` is a redirection
 * operator ('<' or '>'), meaning the command ends with a redirection and is
 * missing its target (equivalent to "syntax error near unexpected token `newline`").
 *
 * Ignores trailing spaces. Quotes don't matter here: only the final non-space
 * character is considered.
 *
 * Returns:
 *  0 on success (no trailing redirection),
 *  non-zero on error (error_msg return value).
 */

int syntax_error_newline(char *str)
{
    int i, last = -1;
    if (!str) return 0;

    for (i = 0; str[i]; ++i)
        if (str[i] != ' ') last = i;

    if (last >= 0 && (str[last] == '>' || str[last] == '<'))
        return error_msg(str, last, 'n');  // “unexpected token `newline`”

    return 0;
}


/*
 * Performs final syntax validation for the command string `str`.
 *
 * Checks:
 *  - The command must not end with a pipe '|'.
 *  - Redirection operators must not appear more than twice consecutively
 *    (rejects ">>>", "<<<").
 *  - The command must not end with a dangling redirection ('>' or '<'
 *    followed only by spaces).
 *
 * Parameters:
 *  str : command string to validate.
 *  i   : current index in the string (caller provides; adjusted inside).
 *  c   : operator character being checked (used for error reporting).
 *
 * Returns:
 *  0 if no syntax error,
 *  -1 if syntax error detected (error_msg called, g_status set to 2).
 */


int	syntax_error_go(char *str, int i, char c)
{
	i--;
	if (str[i] && str[i] == '|')
		return (error_msg(str, i, c));
	if (syntax_error_redir(str, '>') == -1 || syntax_error_redir(str, '<') == -1
		|| syntax_error_newline(str) == -1)
	{
		g_status = 2;
		return (-1);
	}
	return (0);
}


/*
 * Checks for syntax errors related to the operator character `c`
 * (typically '|', ';', or '&') in the command string `str`.
 *
 * Rules enforced:
 *  - The string must not begin with `c`.
 *  - Two `c` operators cannot appear consecutively (even if separated
 *    only by spaces or redirection symbols '>' or '<').
 *  - An operator `c` cannot appear at the very end of the string.
 *  - Operators inside quotes are ignored (skipped over by inside_quote()).
 *
 * Parameters:
 *  str : command line to validate.
 *  c   : operator character to check for (e.g., '|').
 *  i   : starting index (should be passed as -1 by the caller).
 *
 * Returns:
 *  0 on success (no syntax error found),
 *  non-zero if a syntax error is detected (error_msg() return value).
 */

int	syntax_error(char *str, char c, int i)
{
	if (!str)
		return (0);
	if (str[0] == c)
		return (error_msg(str, 0, c));
	while (str[++i] && (str[i] == ' ' || str[i] == '>'
			|| str[i] == '<' || str[i] == c))
		if (str[i] == c)
			return (error_msg(str, i, c));
	while (str[i])
	{
		if ((i = (inside_quote(str, i))) == (int)ft_strlen(str))
			break ;
		if (str[i] && str[i] == c)
		{
			while (str[++i] && (str[i] == ' ' || str[i] == '>'
					|| str[i] == '<' || str[i] == c))
				if (str[i] == c)
					return (error_msg(str, i, c));
			if (str[i] == '\0')
				break ;
		}
		i++;
	}
	return (syntax_error_go(str, i, c));
}
