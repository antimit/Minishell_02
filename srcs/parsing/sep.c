/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   sep.c                                              :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: yviavant <yviavant@student.42.fr>          +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2021/03/12 21:53:21 by yviavant          #+#    #+#             */
/*   Updated: 2021/03/20 03:43:00 by yviavant         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

#include "../../includes/minishell.h"

t_sep	*create_cell(char *cmd_sep)
{
	t_sep	*cell;

	cell = malloc(sizeof(t_sep));
	if (!(cell))
		return (NULL);
	cell->prev = NULL;
	cell->next = NULL;
	cell->pipcell = NULL;
	cell->cmd_sep = cmd_sep;
	return (cell);
}

/*
 * Inserts a new t_sep node into the linked list `list` at the given
 * zero-based position `pos`.
 *
 * Behavior:
 *  - If `list` is NULL, creates the first node and returns it as the new head.
 *  - Otherwise, walks the list until reaching index `pos`, then links
 *    the new cell between `prec` (previous) and `cur` (current).
 *  - The new node’s cmd_sep pointer is set to the provided string.
 *
 * Notes / limitations:
 *  - Inserting at position 0 with a non-empty list will dereference
 *    `prec` uninitialized (bug).
 *  - If `pos` is larger than the list length, `cur` may become NULL and
 *    the loop will misbehave.
 *  - Only the `next` pointers are updated; `prev` is ignored even though
 *    it exists in t_sep.
 *
 * Returns:
 *  The (possibly unchanged) head of the list.
 *
 * Typical usage in minishell:
 *  Called in a loop with increasing `pos` to build the list in order
 *  from an array of command segments.
 */

 
t_sep	*add_cell(t_sep *list, char *cmd_sep, int pos)
{
	t_sep	*prec;
	t_sep	*cur;
	t_sep	*cell;
	int		i;

	cur = list;
	i = 0;
	cell = create_cell(cmd_sep);
	if (list == NULL)
		return (cell);
	while (i < pos)
	{
		i++;
		prec = cur;
		cur = cur->next;
	}
	prec->next = cell;
	cell->next = cur;
	return (list);
}

void	print_list(t_sep *list)
{
	int		i;

	i = 0;
	while (list)
	{
		printf("-----------------------------------\n");
		printf("| i = %d                            \n", i);
		printf("| list->cmd_sep : %s            \n", list->cmd_sep);
		if (list->pipcell != NULL)
			print_pip_list(list->pipcell);
		printf("-----------------------------------\n");
		list = list->next;
		i++;
	}
}
